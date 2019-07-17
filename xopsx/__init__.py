import asyncio
import itertools

import urwid


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


async def new_test_release(widget_cb):
    while True:
        pressed = await info(
            widget_cb,
            "\n".join(
                [
                    "版本转测将依次进行以下步骤：",
                    "  1. 选择 namespace",
                    "  2. 导出 helm 包",
                    "  3. 创建 release 分支",
                    "  4. 导出代码包",
                    "按 ECS 键返回主菜单，SPACE 键继续。",
                ]
            ),
        )
        if pressed == "esc":
            break

        if pressed == " ":
            namespace = await select_namespace(widget_cb)
            if not namespace:
                break

            # await export_helm_tarball(widget_cb, namespace)
            # await create_release_branches(widget_cb)
            # await export_source_codes(widget_cb)
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
        urwid.LineBox(placeholder), event_loop=urwid.AsyncioEventLoop()
    ).start():

        def widget_cb(widget):
            placeholder.original_widget = widget

        await main_menu(widget_cb)
