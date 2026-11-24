// Btn: a small rounded button. accent = filled with the primary color.
import QtQuick

Rectangle {
    id: b
    property string text: ""
    property bool accent: false
    property bool danger: false
    property bool enabled: true
    signal clicked()

    implicitWidth: label.implicitWidth + 24 * Pal.ui
    width: implicitWidth
    height: 26 * Pal.ui
    radius: Pal.radiusMd
    opacity: enabled ? 1 : 0.45
    color: accent ? (area.containsMouse ? Qt.lighter(Pal.primary, 1.08) : Pal.primary)
                  : (area.containsMouse ? Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.16)
                                        : Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.10))

    Text {
        id: label
        anchors.centerIn: parent
        text: b.text
        color: b.accent ? Pal.primaryFg : (b.danger ? Pal.urgent : Pal.text)
        font.family: Pal.font; font.pixelSize: Pal.fsSmall; font.weight: Font.Medium
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (b.enabled) b.clicked()
    }
}
