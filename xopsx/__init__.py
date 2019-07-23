from tempfile import TemporaryDirectory
import asyncio
import contextlib
import collections
import itertools
import os

import urwid
import gitlab

from . import settings, utils


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
                itertools.repeat(["   ", ".  ", ".. ", "..."])
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


async def export_helm_tarball(widget_cb, outdir, namespace):
    K8S_NS_EXPORT = os.path.realpath(
        "./helm-maker/script/k8s-exporter/k8s-ns-export.sh"
    )
    MK_RC_TXT2HELM = os.path.realpath("./helm-maker/script/helm-gen/mk-rc-txt2helm.sh")
    name, version = outdir.split("/")[-2:]
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
                itertools.repeat(["   ", ".  ", ".. ", "..."])
            ):
                yield f"{desc} [{i}]"

        text_iter = text_gen()

        async def task():
            while not finished:
                header.set_text(next(text_iter))
                await asyncio.sleep(0.3)

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

    with progress("[mk-rc-txt2helm.sh] 正在转化为 helm 包"):
        proc = await asyncio.create_subprocess_shell(
            f"{MK_RC_TXT2HELM} {txtdir} {name} {version} {chartdir}",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        await show_output(proc.stdout)
        await proc.wait()

        tarball = os.path.join(outdir, f"{name}-{version}.tar.gz")
        proc = await asyncio.create_subprocess_shell(
            f"tar --verbose --directory {chartdir} --create --gzip --file {tarball} {name}",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        await show_output(proc.stdout)
        await proc.wait()


async def input_name_version(widget_cb):
    result = create_future()
    name_edit = urwid.Edit("名称： ")
    version_edit = urwid.Edit("版本： ")
    submit_button = urwid.Button("确认")

    def submit(_):
        result.set_result((name_edit.edit_text, version_edit.edit_text))

    urwid.connect_signal(submit_button, "click", submit)

    widget = urwid.Padding(
        urwid.ListBox(
            urwid.SimpleFocusListWalker([name_edit, version_edit, submit_button])
        ),
        align="center",
        width=("relative", 30),
    )

    widget_cb(widget)

    return await result


async def create_release_branches(widget_cb, outdir):
    name, version = outdir.split("/")[-2:]
    body = urwid.Text("")
    widget_cb(urwid.Filler(body))

    lines = collections.deque(maxlen=7)

    def log(s):
        lines.append(s)
        body.set_text("\n".join(lines))

    try:
        gl = utils.make_gitlab_client()
    except gitlab.GitlabError as e:
        await info(widget_cb, f"访问 GitLab 失败，{e}")
        return

    log("> 获取项目信息")
    targets = set()
    for dirpath, dirnames, filenames in os.walk(outdir):
        if "srcmeta.txt" in filenames:
            meta = {}
            with open(os.path.join(dirpath, "srcmeta.txt")) as f:
                for line in f:
                    key, val = line.strip().partition("=")[::2]
                    meta[key] = val

                with contextlib.suppress(KeyError):
                    targets.add((meta["CI_PROJECT_ID"], meta["CI_COMMIT_SHA"]))

    branch_name = f"release/{name}-{version}"
    created = []
    for project_id, ref in targets:
        project = gl.projects.get(project_id)
        log(f"> {project.path_with_namespace}: 从 {ref} 创建分支 {branch_name}")
        try:
            project.branches.create({"branch": branch_name, "ref": ref})
            created.append(project.path_with_namespace)
        except gitlab.GitlabError as e:
            log(f"! 创建分支失败，{e}")

    if created:
        await info(
            widget_cb,
            "\n".join([f"已在以下项目创建 {branch_name} 分支：", *["  " + i for i in created]]),
        )


async def new_test_release(widget_cb):

    while True:
        pressed = await info(
            widget_cb,
            "\n".join(
                [
                    "版本转测将依次进行以下步骤：",
                    "  1. 选择 namespace",
                    "  2. 输入名称和版本号",
                    "  3. 导出 helm 包",
                    "  4. 创建 release 分支",
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

            header.set_text("版本转测: 输入名称和版本号")
            name, version = await input_name_version(body_widget_cb)

            outdir = os.path.join(settings.OUTPUT_DIR, name, version)

            try:
                os.makedirs(outdir)
            except FileExistsError:
                await info(body_widget_cb, "版本已存在，无需再次创建！")
                break

            header.set_text(f"版本转测：导出 helm 包 [{name}-{version}.tar.gz]")
            await export_helm_tarball(body_widget_cb, outdir, namespace)

            header.set_text(f"版本转测：创建 release 分支")
            await create_release_branches(body_widget_cb, outdir)

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


async def fetch_source_codes(widget_cb, outdir, branch_name):
    body = urwid.Text("")
    widget_cb(urwid.Filler(body))
    lines = collections.deque(maxlen=12)

    def log(s):
        lines.append(s)
        body.set_text("\n".join(lines))

    try:
        gl = utils.make_gitlab_client()
    except gitlab.GitlabError as e:
        await info(widget_cb, f"访问 GitLab 失败，{e}")
        return

    fetched = []
    for project in gl.projects.list(as_list=False):
        await asyncio.sleep(0.1)
        log(f"> 检测 {project.path_with_namespace}")
        try:
            branch = project.branches.get(branch_name)
            log(f"! 拉取 {project.path_with_namespace} 的 {branch_name} 分支")
            os.makedirs(
                os.path.join(outdir, os.path.dirname(project.path_with_namespace))
            )
            with open(
                os.path.join(outdir, project.path_with_namespace + ".tar.gz"), mode="wb"
            ) as f:
                project.repository_archive(
                    sha=branch_name, streamed=True, target=f.write
                )
            fetched.append(project.path_with_namespace)

        except gitlab.GitlabError:
            with contextlib.suppress(gitlab.GitlabError):
                tag = project.tags.get(branch_name)
                log(f"! 拉取 {project.path_with_namespace} 的 {branch_name} 分支")
                os.makedirs(
                    os.path.join(outdir, os.path.dirname(project.path_with_namespace))
                )
                with open(
                    os.path.join(outdir, project.path_with_namespace + ".tar.gz"),
                    mode="wb",
                ) as f:
                    project.repository_archive(
                        sha=branch_name, streamed=True, target=f.write
                    )
                fetched.append(project.path_with_namespace)

    if fetched:
        await info(widget_cb, "\n".join([f"以获取以下项目的源码：", *["  " + i for i in fetched]]))


async def archive_source_codes(widget_cb):
    while True:
        pressed = await info(
            widget_cb,
            "\n".join(
                [
                    "源代码归档需要输入名称和版本号。",
                    "本程序将拉取 GitLab 上所有项目的以 release/[名称]-[版本号] 命名的分支或 TAG 的源代码。",
                    "按 ECS 键返回主菜单，SPACE 键继续。",
                ]
            ),
        )

        if pressed == "esc":
            break

        if pressed == " ":
            header = urwid.Text("源代码归档")
            body = urwid.WidgetPlaceholder(urwid.Filler(urwid.Text("")))
            frame = urwid.Frame(body, header=header)
            widget_cb(frame)

            def body_widget_cb(widget):
                body.original_widget = widget

            header.set_text("源代码归档：输入版本号")
            name, version = await input_name_version(body_widget_cb)

            outdir = os.path.join(settings.OUTPUT_DIR, name, version, "codes")
            with contextlib.suppress(FileExistsError):
                os.makedirs(outdir)

            branch_name = f"release/{name}-{version}"
            await fetch_source_codes(widget_cb, outdir, branch_name)

            header.set_text("源代码归档：已完成！")
            await info(
                body_widget_cb,
                f"源代码地址：{settings.NGINX_URL}/{outdir}/"
            )
            break


async def main_menu(widget_cb):
    while True:
        chosen = await menu(widget_cb, ("新版本转测", "源代码归档", "退出本程序"))
        if chosen == 0:
            await new_test_release(widget_cb)

        if chosen == 1:
            await archive_source_codes(widget_cb)

        if chosen == 2:
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
