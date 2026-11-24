// FocusRing: the keyboard focus outline drawn around a control while it has active focus.
// Put it inside the control (it fills its parent with a small gap).
import QtQuick

Rectangle {
    property real gap: 3 * Pal.ui
    anchors.fill: parent
    anchors.margins: -gap
    radius: (parent.radius !== undefined ? parent.radius : Pal.radiusSm) + gap
    color: "transparent"
    border.width: 2
    border.color: Pal.primary
    visible: parent.activeFocus
    z: 100
}
