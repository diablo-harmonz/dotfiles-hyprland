// Group: a rounded card holding rows (macOS "inset grouped" list), with an optional
// caption above it. Rows are separated by thin lines (SRow draws its own top line).
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
        text: group.title
        leftPadding: 4 * Pal.ui
        color: Pal.muted
        font.family: Pal.font; font.pixelSize: Pal.fsSmall; font.weight: Font.DemiBold
    }
    Rectangle {
        width: parent.width
        height: rows.implicitHeight
        radius: Pal.radius
        color: Pal.card
        border.color: Pal.line
        border.width: 1
        clip: true
        Column {
            id: rows
            width: parent.width
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
