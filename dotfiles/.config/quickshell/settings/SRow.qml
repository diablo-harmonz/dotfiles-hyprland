// SRow: one row of a Group: optional icon, title, subtitle on the left, controls on the
// right (children). clickable rows highlight on hover and emit clicked().
// Icons are flat and in the text colour (no colour coding), in both looks.
// HUD look (Pal.hud): its own thin frame (brighter on hover), UPPERCASE spaced title.
import QtQuick

Item {
    id: row
    property string icon: ""
    property color iconColor: Pal.muted
    property string title: ""
    property string subtitle: ""
    property bool clickable: false
    property bool first: (parent && parent.children.length > 0 && parent.children[0] === row)
    default property alias controls: right.data
    signal clicked()

    width: parent ? parent.width : 0
    height: Math.max(Pal.rowH, texts.implicitHeight + 16 * Pal.ui)

    Rectangle {   // separator
        visible: !row.first && !Pal.hud
        anchors.top: parent.top
        x: Pal.pad; width: parent.width - Pal.pad
        height: 1
        color: Pal.line
    }
    Rectangle {
        anchors.fill: parent
        radius: Pal.hud ? Pal.radiusMd : 0
        color: area.containsMouse && row.clickable ? Pal.hover : "transparent"
        border.width: Pal.hud ? 1 : 0
        border.color: area.containsMouse && row.clickable ? Pal.outlineHot : Pal.outline
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: row.clickable
        enabled: row.clickable
        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: row.clicked()
    }

    Text {
        id: ico
        visible: row.icon !== ""
        anchors.verticalCenter: parent.verticalCenter
        x: Pal.pad
        width: 20 * Pal.ui
        horizontalAlignment: Text.AlignHCenter
        text: row.icon
        // Flat, one colour in both looks: only the warning colour keeps its meaning (e.g. low
        // battery); its alpha is kept (the Wi-Fi list shows signal strength that way)
        color: !Qt.colorEqual(row.iconColor, Pal.urgent)
               ? Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, row.iconColor.a) : row.iconColor
        font.family: Pal.icons; font.pixelSize: 15 * Pal.ui
    }
    Column {
        id: texts
        anchors.verticalCenter: parent.verticalCenter
        x: row.icon !== "" ? ico.x + ico.width + 10 * Pal.ui : Pal.pad
        width: right.x - x - 10 * Pal.ui
        spacing: 1 * Pal.ui
        Text {
            width: parent.width
            text: Pal.label(row.title)
            elide: Text.ElideRight
            color: Pal.text
            font.family: Pal.font; font.pixelSize: Pal.fs
            font.letterSpacing: Pal.tracking
        }
        Text {
            visible: row.subtitle !== ""
            width: parent.width
            text: row.subtitle
            elide: Text.ElideRight
            color: Pal.muted
            font.family: Pal.font; font.pixelSize: Pal.fsSmall
        }
    }
    Row {
        id: right
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Pal.pad
        spacing: 8 * Pal.ui
    }
}
