// Seg: a segmented control. options = [{ key, label }], current = key, picked(key).
import QtQuick

Rectangle {
    id: seg
    property var options: []
    property string current: ""
    signal picked(string key)

    width: row.implicitWidth + 4 * Pal.ui
    height: 26 * Pal.ui
    radius: Pal.radiusMd
    color: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.10)

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
                color: on ? Pal.primary : (a.containsMouse ? Pal.hover : "transparent")
                Text {
                    id: t
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.on ? Pal.primaryFg : Pal.text
                    font.family: Pal.font; font.pixelSize: Pal.fsSmall; font.weight: Font.Medium
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
