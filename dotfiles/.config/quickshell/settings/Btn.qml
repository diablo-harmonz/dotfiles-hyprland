// Btn: a small rounded button. accent = filled with the primary color.
// HUD look (Pal.hud): outlined, UPPERCASE spaced text; accent = primary outline and text.
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
    color: Pal.hud ? (area.containsMouse ? Pal.hover : "transparent")
         : accent ? (area.containsMouse ? Qt.lighter(Pal.primary, 1.08) : Pal.primary)
                  : (area.containsMouse ? Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.16)
                                        : Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.10))
    border.width: Pal.hud ? 1 : 0
    border.color: accent ? Pal.primary : (area.containsMouse ? Pal.outlineHot : Pal.outline)

    Text {
        id: label
        anchors.centerIn: parent
        text: Pal.label(b.text)
        color: b.accent ? (Pal.hud ? Pal.primary : Pal.primaryFg) : (b.danger ? Pal.urgent : Pal.text)
        font.family: Pal.font; font.pixelSize: Pal.fsSmall; font.weight: Font.Medium
        font.letterSpacing: Pal.tracking
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (b.enabled) b.clicked()
    }
}
