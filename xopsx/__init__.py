import asyncio

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


async def info(widget_cb, text):
    confirmed = create_future()
    widget = urwid.Filler(urwid.Text(text))
    widget.selectable = lambda: True
    widget.keypress = lambda *_: confirmed.set_result(True)
    widget_cb(widget)
    await confirmed


async def new_test_release(widget_cb):
    await info(widget_cb, ".....................")


async def main_menu(widget_cb):
    chosen = await menu(widget_cb, ("新版本转测", "退出本程序"))
    if chosen == 0:
        await new_test_release(widget_cb)

    if chosen == 1:
        pass


async def run():
    placeholder = urwid.WidgetPlaceholder(urwid.Filler(urwid.Text("Initialize...")))
    with urwid.MainLoop(
        urwid.LineBox(placeholder), event_loop=urwid.AsyncioEventLoop()
    ).start():

        def widget_cb(widget):
            placeholder.original_widget = widget

        await main_menu(widget_cb)
