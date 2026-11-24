// Group: a rounded card holding rows (macOS "inset grouped" list), with an optional
// caption above it. Rows are separated by thin lines (SRow draws its own top line).
// HUD look (Pal.hud): no card, the rows are separate outlined frames with a gap.
import QtQuick

Column {
    id: group
    property string title: ""
    property string footer: ""
    default property alias content: rows.data
    width: parent ? parent.width : 0
    spacing: 6 * Pal.ui

    Text {
        visible: group.title !== ""
        text: Pal.label(group.title)
        font.letterSpacing: Pal.tracking
        leftPadding: 4 * Pal.ui
        color: Pal.muted
        font.family: Pal.font; font.pixelSize: Pal.fsSmall; font.weight: Font.DemiBold
    }
    Rectangle {
        width: parent.width
        height: rows.implicitHeight
        radius: Pal.radiusMd
        color: Pal.hud ? "transparent" : Pal.card
        border.color: Pal.line
        border.width: Pal.hud ? 0 : 1
        clip: !Pal.hud
        Column {
            id: rows
            width: parent.width
            spacing: Pal.hud ? 6 * Pal.ui : 0
        }
    }
    Text {
        visible: group.footer !== ""
        width: parent.width
        text: group.footer
        leftPadding: 4 * Pal.ui
        wrapMode: Text.WordWrap
        color: Pal.muted
        font.family: Pal.font; font.pixelSize: Pal.fsSmall
    }
}
