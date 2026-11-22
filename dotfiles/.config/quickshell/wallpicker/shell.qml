// wallpicker: wallpaper carousel for SUPER+W (bin/wallpaper select). Run on demand,
// quits after a choice, so it uses no memory while closed.
//   ← → / h l / wheel   move        Enter / click the middle one   set it
//   click another one   move there  Esc / click outside / SUPER+W  close
// Tall tiles across the screen: the middle one largest, the others smaller and turned
// away in perspective the further out they are. Look inspired by hyprquickpaper in
// 43PR/dotfiles (MIT); written anew for bin/wallpaper (thumbnails, Matugen, awww).
// bin/wallpaper passes the screen (WALLPICKER_SCREEN) and the accent color from Matugen
// (WALLPICKER_ACCENT); images come from `wallpaper list-thumbs`.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string accent: "#" + (Quickshell.env("WALLPICKER_ACCENT") || "94cdf7")

    PanelWindow {
        id: win
        screen: {
            const want = Quickshell.env("WALLPICKER_SCREEN")
            const list = Quickshell.screens
            for (let i = 0; i < list.length; i++)
                if (list[i].name === want) return list[i]
            return list[0]
        }
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "wallpicker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // ---- look (sizes scale with the screen height; tuned on 1920x1200) ----------
        readonly property real ui: height / 1200
        readonly property real tileH: 520 * ui          // middle tile
        readonly property real tileW: tileH / 2
        readonly property real gap: 14 * ui
        readonly property real shrink: 0.13             // size lost per step from the middle
        readonly property real minScale: 0.42
        readonly property real maxTilt: 30              // degrees, reached 6 steps out
        readonly property real depth: 2.6               // camera distance in tile widths
        readonly property real centerY: height * 0.54

        // ---- state ----------------------------------------------------------------------
        property int target: 0          // index of the chosen tile
        property real pos: 0            // animated position (follows target)
        property bool ready: false      // the current wallpaper is centred: start animating
        property bool closing: false
        property real shown: 0          // 0 -> 1 intro, 1 -> 0 on close

        Behavior on pos { enabled: win.ready; NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        NumberAnimation on shown { id: intro; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
        NumberAnimation { id: outro; target: win; property: "shown"; to: 0; duration: 160
                          onFinished: Qt.quit() }

        ListModel { id: images }

        function move(step) {
            if (images.count === 0) return
            target = Math.max(0, Math.min(images.count - 1, target + step))
            pos = target
        }
        function close() {
            if (closing) return
            closing = true
            outro.start()
        }
        function choose(i) {
            if (closing || i < 0 || i >= images.count) return
            Quickshell.execDetached(["sh", "-c", "exec \"$HOME/.local/bin/wallpaper\" set \"$1\"", "sh",
                                     images.get(i).path])
            close()
        }

        // Width-weighted distance from the middle to slot t (continuous, so tiles glide)
        function offsetFor(t) {
            const a = Math.abs(t)
            const knee = (1 - minScale) / shrink
            const u = Math.min(a, knee)
            let w = tileW * (u - shrink * u * u / 2)
            if (a > knee) w += tileW * minScale * (a - knee)
            return Math.sign(t) * (w + gap * a)
        }

        Process {
            running: true
            command: ["sh", "-c", "exec \"$HOME/.local/bin/wallpaper\" list-thumbs"]
            stdout: SplitParser {
                onRead: line => {
                    const f = line.split("\t")
                    if (f.length < 3) return
                    images.append({ path: f[0], thumb: f[1] })
                    if (f[2] === "1") { win.target = images.count - 1; win.pos = win.target }
                }
            }
            onExited: { win.pos = win.target; win.ready = true }
        }

        // Dim the desktop a little so the tiles stand out
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5 * win.shown
        }

        // Click outside the tiles: close
        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
            onWheel: wheel => {
                const d = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x
                win.move(d > 0 ? -1 : 1)
            }
        }

        Item {
            id: strip
            anchors.fill: parent
            focus: true
            opacity: win.shown
            transform: Translate { y: (1 - win.shown) * 30 * win.ui }

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left: case Qt.Key_H: case Qt.Key_Up: case Qt.Key_K:
                    win.move(-1); break
                case Qt.Key_Right: case Qt.Key_L: case Qt.Key_Down: case Qt.Key_J:
                    win.move(1); break
                case Qt.Key_Home: win.move(-images.count); break
                case Qt.Key_End: win.move(images.count); break
                case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
                    win.choose(win.target); break
                case Qt.Key_Escape: case Qt.Key_Q:
                    win.close(); break
                default: return
                }
                event.accepted = true
            }

            Repeater {
                model: images

                Item {
                    id: tile
                    required property int index
                    required property string path
                    required property string thumb

                    readonly property real d: index - win.pos
                    readonly property real s: Math.max(win.minScale, 1 - win.shrink * Math.abs(d))
                    readonly property bool middle: index === win.target
                    readonly property real cx: win.width / 2 + win.offsetFor(d)
                    // Signed turn, growing with the distance: the inner edge stays nearer
                    readonly property real tilt: Math.sign(d) * win.maxTilt
                                                 * Math.pow(Math.min(1, Math.abs(d) / 6), 1.2) * Math.PI / 180

                    width: win.tileW * s
                    height: win.tileH * s
                    x: cx - width / 2
                    y: win.centerY - height / 2
                    z: 1000 - Math.round(Math.abs(d) * 10)
                    visible: x < win.width && x + width > 0

                    // Rotation about the vertical centre line with a perspective divide
                    // (QML's Rotation has no perspective)
                    transform: Matrix4x4 {
                        matrix: {
                            const a = tile.tilt
                            if (Math.abs(a) < 1e-4) return Qt.matrix4x4()
                            const c = Math.cos(a), sn = Math.sin(a)
                            const cx = tile.width / 2, cy = tile.height / 2
                            const k = sn / Math.max(1, tile.width * win.depth)
                            return Qt.matrix4x4(c + cx * k, 0, 0, cx * (1 - c) - cx * cx * k,
                                                cy * k,     1, 0, -cx * cy * k,
                                                0,          0, 1, 0,
                                                k,          0, 0, 1 - cx * k)
                        }
                    }

                    // Shadow
                    Rectangle {
                        x: 6 * win.ui; y: 8 * win.ui
                        width: parent.width; height: parent.height
                        color: "#000000"
                        opacity: 0.45
                        radius: 4 * win.ui
                    }

                    Image {
                        anchors.fill: parent
                        source: "file://" + tile.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        opacity: tile.middle ? 1 : 0.8
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Accent frame on the chosen one
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3 * win.ui
                        color: "transparent"
                        border.color: root.accent
                        border.width: 2 * win.ui
                        radius: 4 * win.ui
                        opacity: tile.middle ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tile.middle ? win.choose(tile.index) : win.move(tile.index - win.target)
                        onWheel: wheel => {
                            const dd = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : -wheel.angleDelta.x
                            win.move(dd > 0 ? -1 : 1)
                        }
                    }
                }
            }

            // Name of the chosen wallpaper, under the strip
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.centerY + win.tileH / 2 + 28 * win.ui
                text: images.count > 0
                      ? images.get(win.target).path.split("/").pop().replace(/\.[^.]+$/, "")
                        + "   " + (win.target + 1) + "/" + images.count
                      : "Loading wallpapers..."
                color: "#ffffff"
                opacity: 0.85
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 15 * win.ui
                style: Text.Raised
                styleColor: "#80000000"
            }
        }
    }
}
