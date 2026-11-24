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
