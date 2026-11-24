// Page: the right side: a title and a scrolling column of Groups.
import QtQuick

Flickable {
    id: page
    property string title: ""
    default property alias content: body.data
    // Emitted each time the panel opens again with this page loaded: re-read one-off data
    signal reopened()
    Connections {
        target: Pal
        function onOpenChanged() { if (Pal.open) page.reopened() }
    }
    contentHeight: body.implicitHeight + 48 * Pal.ui

    // Keyboard: keep the focused control in view (scroll only as far as needed)
    function reveal(item) {
        let it = item
        while (it && it !== body) it = it.parent
        if (!it) return                                   // not on this page
        const p = item.mapToItem(body, 0, 0)
        const top = body.y + p.y - 12 * Pal.ui, bottom = body.y + p.y + item.height + 12 * Pal.ui
        if (top < contentY) contentY = Math.max(0, top)
        else if (bottom > contentY + height) contentY = Math.min(contentHeight - height, bottom - height)
    }
    Connections {
        target: page.Window.window
        ignoreUnknownSignals: true
        function onActiveFocusItemChanged() {
            const w = page.Window.window
            if (w && w.activeFocusItem) page.reveal(w.activeFocusItem)
        }
    }
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: body
        x: 28 * Pal.ui
        y: 22 * Pal.ui
        width: page.width - 56 * Pal.ui
        spacing: 18 * Pal.ui
        Text {
            text: Pal.label(page.title)
            color: Pal.text
            font.family: Pal.font; font.pixelSize: Pal.fsTitle
            font.weight: Pal.hud ? Font.Light : Font.Bold
            font.letterSpacing: Pal.hud ? 5 * Pal.ui : 0
        }
    }
}
