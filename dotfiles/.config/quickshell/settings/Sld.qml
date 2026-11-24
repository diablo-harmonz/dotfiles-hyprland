// Sld: a slider 0..1. `value` follows the source; moved(v) while dragging or clicking.
import QtQuick

Item {
    id: s
    property real value: 0
    property bool dim: false          // e.g. muted
    signal moved(real v)
    readonly property real radius: height / 2   // for the focus ring

    // Keyboard: Tab / ↑ ↓ move between controls, Esc back to the sidebar
    activeFocusOnTab: true
    Keys.onUpPressed: Pal.focusStep(s, false)
    Keys.onDownPressed: Pal.focusStep(s, true)
    Keys.onEscapePressed: Pal.sidebarRequested()
    // ← → change it by 5 %
    Keys.onLeftPressed: s.moved(Math.max(0, Math.round((s.value - 0.05) * 100) / 100))
    Keys.onRightPressed: s.moved(Math.min(1, Math.round((s.value + 0.05) * 100) / 100))

    width: 200 * Pal.ui
    height: 22 * Pal.ui
    readonly property real shown: area.pressed ? drag : Math.max(0, Math.min(1, value))
    property real drag: 0

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6 * Pal.ui
        radius: height / 2
        color: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.15)
        Rectangle {
            width: Math.max(parent.height, parent.width * s.shown)
            height: parent.height
            radius: parent.radius
            color: s.dim ? Pal.muted : Pal.primary
        }
    }
    Rectangle {
        width: 16 * Pal.ui
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: (s.width - width) * s.shown
        color: "#ffffff"
        border.color: Qt.rgba(0, 0, 0, 0.15)
    }
    FocusRing {}
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(mx) { return Math.max(0, Math.min(1, mx / s.width)) }
        onPressed: m => { s.drag = at(m.x); s.moved(s.drag) }
        onPositionChanged: m => { if (pressed) { s.drag = at(m.x); s.moved(s.drag) } }
        onWheel: w => s.moved(Math.max(0, Math.min(1, s.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
