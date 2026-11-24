// Toggle: a macOS-style switch. Set `checked`, react to toggled(value).
import QtQuick

Rectangle {
    id: sw
    property bool checked: false
    property bool busy: false
    signal toggled(bool value)

    width: 38 * Pal.ui
    height: 22 * Pal.ui
    radius: height / 2
    color: checked ? Pal.primary : Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.18)
    opacity: busy ? 0.6 : 1
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: parent.height - 4 * Pal.ui
        height: width
        radius: width / 2
        y: 2 * Pal.ui
        x: sw.checked ? sw.width - width - 2 * Pal.ui : 2 * Pal.ui
        color: "#ffffff"
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!sw.busy) sw.toggled(!sw.checked)
    }
}
