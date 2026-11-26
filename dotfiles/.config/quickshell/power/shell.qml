// power: the power menu for SUPER+Escape and the Waybar power button (bin/power-menu).
// Runs on demand and quits after a choice, so it uses no memory while closed.
//   arrows / mouse             move the highlight    Enter / click   run it
//   l u h s f e r b            run a tile directly   Esc / click outside / SUPER+Escape   close
// A 4 x 2 grid of tiles over the dimmed, blurred desktop (Hyprland blurs the "power-menu"
// layer, hypr/conf/windowrules.lua). The chosen action runs after the close animation, so
// the lock screen or a suspend never catches the menu still on screen.
// Colors: Matugen's ~/.config/rofi/colors.rasi (as in the Settings panel), shapes and fonts:
// Tokens (bin/tokens). bin/power-menu passes the focused screen (POWER_SCREEN).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // Self-test (QS_SELFTEST=1, bin/dotfiles-verify): the config loaded, so quit at once
    readonly property bool selftest: (Quickshell.env("QS_SELFTEST") || "") !== ""
    Timer { running: root.selftest; interval: 50; onTriggered: { console.info("SELFTEST done"); Qt.quit() } }

    // ---- the tiles: label, Nerd Font glyph, letter key, command (run by sh -c) -------------
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"
    readonly property var items: [
        { label: "Lock",       glyph: "", key: "l", cmd: "loginctl lock-session" },
        { label: "Suspend",    glyph: "", key: "u", cmd: "exec \"" + bin + "sleep-now\"" },
        { label: "Hibernate",  glyph: "", key: "h", cmd: "systemctl hibernate" },
        { label: "Shutdown",   glyph: "", key: "s", cmd: "systemctl poweroff" },
        { label: "Force quit", glyph: "", key: "f", cmd: "exec \"" + bin + "force-quit\"" },
        { label: "Logout",     glyph: "", key: "e", cmd: "hyprctl dispatch 'hl.dsp.exit()'" },
        { label: "Reboot",     glyph: "", key: "r", cmd: "systemctl reboot" },
        { label: "BIOS",       glyph: "", key: "b", cmd: "systemctl reboot --firmware-setup" }
    ]
    readonly property int cols: 4

    // ---- colors from Matugen (rofi writes #rrggbbaa, Qt wants #aarrggbb) -------------------
    property color surface: "#ff262a33"
    property color primary: "#ffadc7ff"
    property color text: "#ffdfe2ef"
    property color muted: "#ffc3c6d3"
    function rofiColor(s) { return s.length === 9 ? "#" + s.substr(7, 2) + s.substr(1, 6) : s }
    FileView {
        id: colors
        path: Quickshell.env("HOME") + "/.config/rofi/colors.rasi"
        onLoaded: {
            const re = /^\s*([a-z-]+):\s*(#[0-9a-fA-F]{6,8});/gm
            const src = colors.text()
            let m
            while ((m = re.exec(src)) !== null) {
                const c = root.rofiColor(m[2])
                if (m[1] === "surface") root.surface = c
                else if (m[1] === "primary") root.primary = c
                else if (m[1] === "text") root.text = c
                else if (m[1] === "text-muted") root.muted = c
            }
        }
    }

    PanelWindow {
        id: win
        visible: !root.selftest
        screen: {
            const want = Quickshell.env("POWER_SCREEN")
            const list = Quickshell.screens
            for (let i = 0; i < list.length; i++)
                if (list[i].name === want) return list[i]
            return list[0]
        }
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "power-menu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // ---- look (scales with the screen height; tuned on 1920x1200) -----------------------
        readonly property real ui: height / 1200
        readonly property real tileW: 300 * ui
        readonly property real tileH: 190 * ui
        readonly property real gap: 14 * ui
        readonly property bool hud: Tokens.uiStyle === "hud"      // Cosmos: mono, UPPERCASE

        // ---- state -------------------------------------------------------------------------
        property int current: 0
        property int chosen: -1          // runs when the close animation ends
        property bool closing: false
        property real shown: 0           // 0 -> 1 intro, 1 -> 0 on close

        NumberAnimation on shown { from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation {
            id: outro; target: win; property: "shown"; to: 0; duration: 120
            onFinished: {
                if (win.chosen >= 0)
                    Quickshell.execDetached(["sh", "-c", root.items[win.chosen].cmd])
                Qt.quit()
            }
        }

        function close() { if (!closing) { closing = true; outro.start() } }
        function run(i) { if (!closing && i >= 0 && i < root.items.length) { chosen = i; close() } }
        function move(dx, dy) {
            const n = root.items.length, rows = Math.ceil(n / root.cols)
            let c = current % root.cols, r = Math.floor(current / root.cols)
            c = (c + dx + root.cols) % root.cols
            r = (r + dy + rows) % rows
            current = Math.min(n - 1, r * root.cols + c)
        }

        // Dimmed backdrop; a click outside the tiles closes the menu
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.25 * win.shown
        }
        MouseArea { anchors.fill: parent; onClicked: win.close() }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: root.cols
            spacing: win.gap
            focus: true
            opacity: win.shown
            scale: 0.96 + 0.04 * win.shown

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left:  win.move(-1, 0); break
                case Qt.Key_Right: win.move(1, 0); break
                case Qt.Key_Up:    win.move(0, -1); break
                case Qt.Key_Down:  win.move(0, 1); break
                case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                    win.run(win.current); break
                case Qt.Key_Escape: case Qt.Key_Q:
                    win.close(); break
                default: {
                    // Letter keys run their tile at once
                    const i = root.items.findIndex(it => it.key === event.text.toLowerCase())
                    if (i < 0) return
                    win.current = i
                    win.run(i)
                }
                }
                event.accepted = true
            }

            Repeater {
                model: root.items
                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool active: win.current === index

                    width: win.tileW
                    height: win.tileH
                    radius: Tokens.radiusLg * win.ui
                    color: active ? Qt.rgba(root.surface.r, root.surface.g, root.surface.b, 0.95)
                                  : Qt.rgba(root.surface.r, root.surface.g, root.surface.b, 0.6)
                    border.width: active ? Math.max(1, Tokens.border * win.ui) : 0
                    border.color: root.primary
                    Behavior on color { ColorAnimation { duration: 90 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 22 * win.ui
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.glyph
                            font.family: Tokens.fontMono
                            font.pixelSize: 56 * win.ui
                            color: tile.active ? root.primary : root.text
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.hud ? tile.modelData.label.toUpperCase() : tile.modelData.label
                            font.family: win.hud ? Tokens.fontMono : Tokens.fontUi
                            font.pixelSize: 17 * win.ui
                            font.letterSpacing: win.hud ? 1.6 * win.ui : 0
                            color: root.text
                        }
                    }
                    // The letter key, small in the corner
                    Text {
                        anchors { top: parent.top; right: parent.right; margins: 12 * win.ui }
                        text: tile.modelData.key.toUpperCase()
                        font.family: Tokens.fontMono
                        font.pixelSize: 12 * win.ui
                        color: root.muted
                        opacity: 0.7
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.current = tile.index
                        onClicked: win.run(tile.index)
                    }
                }
            }
        }
    }
}
