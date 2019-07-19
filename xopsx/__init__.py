from tempfile import TemporaryDirectory
import asyncio
import contextlib
import collections
import itertools
import os

import urwid

from . import settings


def create_future():
    loop = asyncio.get_running_loop()
    return loop.create_future()


async def menu(widget_cb, choices):
    chosen = create_future()

    items = []
    for index, label in enumerate(choices):
        button = urwid.Button(label)
        urwid.connect_signal(button, "click", lambda _, i: chosen.set_result(i), index)
        items.append(button)

    widget = urwid.ListBox(urwid.SimpleFocusListWalker(items))
    widget_cb(widget)

    return await chosen


async def info(widget_cb, text, wait_for_key=True):
    widget = urwid.Padding(
        urwid.Filler(urwid.Text(text)), align="center", width=("relative", 80)
    )
    widget_cb(widget)

    if wait_for_key:
        pressed = create_future()
        widget.selectable = lambda: True

        def keypress_cb(size, key):
            pressed.set_result(key)
            widget.selectable = lambda: False

        widget.keypress = keypress_cb
        return await pressed


async def select_namespace(widget_cb):
    loop = asyncio.get_event_loop()
    selected = create_future()

    fetched = False

    async def progress():
        def text_gen():
            for i in itertools.chain.from_iterable(
                itertools.repeat([".  ", ".. ", "..."])
            ):
                yield f"正在获取 namespace 列表 [{i}]"

        text_iter = text_gen()
        while not fetched:
            await info(widget_cb, next(text_iter), wait_for_key=False)
            await asyncio.sleep(0.1)

    loop.create_task(progress())

    proc = await asyncio.create_subprocess_shell(
        "kubectl get namespaces -o name",
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    out, err = await proc.communicate()
    fetched = True

    if err:
        await info(
            widget_cb,
            "\n".join(["获取 namespace 列表失败！", "ERROR: {}".format(err.decode("utf-8"))]),
        )
        return None

    items = []
    namespaces = [ns[len("namespace/") :] for ns in out.decode("utf-8").splitlines()]

    if not namespaces:
        await info(widget_cb, "namespace 列表为空，流程终止！")
        return None

    for ns in namespaces:
        button = urwid.Button(ns)
        urwid.connect_signal(button, "click", lambda _, x: selected.set_result(x), ns)
        items.append(button)

    widget = urwid.ListBox(urwid.SimpleFocusListWalker(items))
    widget_cb(widget)

    return await selected


async def export_helm_tarball(widget_cb, outdir, namespace, version):
    K8S_NS_EXPORT = os.path.realpath(
        "./helm-maker/script/k8s-exporter/k8s-ns-export.sh"
    )
    MK_RC_TXT2HELM = os.path.realpath("./helm-maker/script/helm-gen/mk-rc-txt2helm.sh")
    tarball = create_future()

    header = urwid.Text("")
    body = urwid.Text("...")
    frame = urwid.Frame(urwid.Filler(body), header=header)
    widget_cb(frame)

    def header_widget_cb(widget):
        header.original_widget = widget

    @contextlib.contextmanager
    def progress(desc):
        loop = asyncio.get_event_loop()
        finished = False

        def text_gen():
            for i in itertools.chain.from_iterable(
                itertools.repeat([".  ", ".. ", "..."])
            ):
                yield f"{desc} [{i}]"

        text_iter = text_gen()

        async def task():
            while not finished:
                header.set_text(next(text_iter))
                await asyncio.sleep(0.1)

        try:
            loop.create_task(task())
            yield
        finally:
            finished = True

    async def show_output(reader):
        lines = collections.deque(maxlen=7)
        while not reader.at_eof():
            line = await reader.readline()
            lines.append("> " + line.decode("utf-8"))
            body.set_text("".join(lines))

    txtdir = os.path.join(outdir, "txt")
    chartdir = os.path.join(outdir, "chart")

    with progress("[k8s-ns-export.sh] 正在导出 txt 中间格式"):
        proc = await asyncio.create_subprocess_shell(
            f"{K8S_NS_EXPORT} {namespace} {txtdir}",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        await show_output(proc.stdout)
        await proc.wait()

    # with progress("[mk-rc-txt2helm.sh] 正在转化为 helm 包"):
    #     proc = await asyncio.create_subprocess_shell(
    #         f"cd {chartdir}; {MK_RC_TXT2HELM} {txtdir} {namespace} {version}",
    #         stdout=asyncio.subprocess.PIPE,
    #         stderr=asyncio.subprocess.STDOUT,
    #     )
    #     await show_output(proc.stdout)
    #     await proc.wait()

    tarball.set_result(None)

    return await tarball


async def input_version(widget_cb):
    version = create_future()

    class MyWidget(urwid.Filler):
        def __init__(self):
            return super(MyWidget, self).__init__(urwid.Edit("版本号： "))

        def keypress(self, size, key):
            if key == "enter":
                version.set_result(self.body.edit_text)
            else:
                return super(MyWidget, self).keypress(size, key)

    widget_cb(MyWidget())

    return await version


async def new_test_release(widget_cb):

    while True:
        pressed = await info(
            widget_cb,
            "\n".join(
                [
                    "版本转测将依次进行以下步骤：",
                    "  1. 选择 namespace",
                    "  2. 输入版本号",
                    "  3. 导出 helm 包",
                    "  4. 创建 release 分支",
                    "  5. 导出代码包",
                    "按 ECS 键返回主菜单，SPACE 键继续。",
                ]
            ),
        )
        if pressed == "esc":
            break

        if pressed == " ":
            header = urwid.Text("")
            body = urwid.WidgetPlaceholder(urwid.Filler(urwid.Text("")))
            frame = urwid.Frame(body, header=header)
            widget_cb(frame)

            def body_widget_cb(widget):
                body.original_widget = widget

            header.set_text("版本转测：选择 namespace")
            namespace = await select_namespace(body_widget_cb)
            if not namespace:
                break

            header.set_text("版本转测: 输入版本号")
            version = await input_version(body_widget_cb)

            outdir = os.path.join(settings.OUTPUT_DIR, namespace, version)

            try:
                os.makedirs(outdir)
            except FileExistsError:
                await info(body_widget_cb, "版本已存在，无需再次创建！")
                break

            header.set_text(f"版本转测：导出 helm 包 [{namespace}-{version}.tar.gz]")

            await export_helm_tarball(body_widget_cb, outdir, namespace, version)
            # await create_release_branches(widget_cb)
            # await export_source_codes(widget_cb)

            header.set_text("版本转测：已完成！")
            await info(
                body_widget_cb,
                "\n".join(
                    [
                        f"helm 包地址：{settings.NGINX_URL}/{namespace}/{version}/{namespace}-{version}.tar.gz"
                    ]
                ),
            )
            break


async def main_menu(widget_cb):
    while True:
        chosen = await menu(widget_cb, ("新版本转测", "退出本程序"))
        if chosen == 0:
            await new_test_release(widget_cb)

        if chosen == 1:
            break


async def run():
    placeholder = urwid.WidgetPlaceholder(urwid.Filler(urwid.Text("Initialize...")))
    with urwid.MainLoop(
        urwid.LineBox(placeholder),
        event_loop=urwid.AsyncioEventLoop(),
        handle_mouse=False,
    ).start():

        def widget_cb(widget):
            placeholder.original_widget = widget

        await main_menu(widget_cb)