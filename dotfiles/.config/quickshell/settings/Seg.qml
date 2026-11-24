// Seg: a segmented control. options = [{ key, label }], current = key, picked(key).
// HUD look (Pal.hud): outlined; the chosen segment has a primary outline and text.
import QtQuick

Rectangle {
    id: seg
    property var options: []
    property string current: ""
    signal picked(string key)

    width: row.implicitWidth + 4 * Pal.ui
    height: 26 * Pal.ui
    radius: Pal.radiusMd
    color: Pal.hud ? "transparent" : Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.10)
    border.width: Pal.hud ? 1 : 0
    border.color: Pal.outline

    Row {
        id: row
        x: 2 * Pal.ui; y: 2 * Pal.ui
        Repeater {
            model: seg.options
            Rectangle {
                required property var modelData
                readonly property bool on: modelData.key === seg.current
                width: t.implicitWidth + 20 * Pal.ui
                height: seg.height - 4 * Pal.ui
                radius: Pal.radiusSm
                color: on && !Pal.hud ? Pal.primary : (a.containsMouse ? Pal.hover : "transparent")
                border.width: on && Pal.hud ? 1 : 0
                border.color: Pal.primary
                Text {
                    id: t
                    anchors.centerIn: parent
                    text: Pal.label(modelData.label)
                    color: parent.on ? (Pal.hud ? Pal.primary : Pal.primaryFg) : Pal.text
                    font.family: Pal.font; font.pixelSize: Pal.fsSmall; font.weight: Font.Medium
                    font.letterSpacing: Pal.tracking
                }
                MouseArea {
                    id: a
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.picked(modelData.key)
                }
            }
        }
    }
}
