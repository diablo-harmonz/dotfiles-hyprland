// settings: macOS-style System Settings panel (bin/settings, SUPER+comma, the gear icon in
// Waybar). Started on demand and quits when closed, so it uses no memory or CPU otherwise.
//   sidebar      General (you and a quick status) / Wi-Fi, Bluetooth / Sound, Displays,
//                Battery / Storage, About / Appearance, Configs  (one file each: <Key>Page.qml)
//   ↑ ↓          previous / next section (while no text field has focus)
//   Esc / click outside / SUPER+comma   close
// Lazy: only the open section is loaded (Loader), so NetworkManager, BlueZ, PipeWire and
// UPower are only started, and Wi-Fi / Bluetooth only scanned, when their section is opened.
// The General section reads its quick status with a few small commands instead.
// Smooth opening (the idea of 43PR/dotfiles' PopupLifecycle.qml): nothing shows (not even the
// dimmed backdrop) until the page is loaded and 3 frames were drawn (600 ms at most); until
// then the panel is drawn at opacity 0.004, invisible, so the GPU has its shaders ready. Then
// the whole panel fades in at once.
// SETTINGS_PAGE / SETTINGS_SCREEN (set by bin/settings) pick the section and the screen.
// Look: Pal.qml (Matugen colors from rofi/colors.rasi), Group / SRow / Toggle / Sld / Btn /
// Seg for the controls. Pages close the panel with Pal.closeRequested().
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // key, label, Nerd Font glyph, tile color; "" = gap between sidebar groups
    readonly property var sections: [
        { key: "General",    label: "General",    glyph: "", color: "#636366" },
        { key: "" },
        { key: "Network",    label: "Wi-Fi",      glyph: "", color: "#0a84ff" },
        { key: "Bluetooth",  label: "Bluetooth",  glyph: "", color: "#0a84ff" },
        { key: "" },
        { key: "Sound",      label: "Sound",      glyph: "", color: "#ff375f" },
        { key: "Display",    label: "Displays",   glyph: "", color: "#0a84ff" },
        { key: "Power",      label: "Battery",    glyph: "", color: "#30d158" },
        { key: "" },
        { key: "Storage",    label: "Storage",    glyph: "", color: "#8e8e93" },
        { key: "System",     label: "About",      glyph: "", color: "#8e8e93" },
        { key: "" },
        { key: "Appearance", label: "Appearance", glyph: "󰏘", color: "#bf5af2" },
        { key: "Configs",    label: "Configs",    glyph: "", color: "#ff9f0a" }
    ]
    readonly property var keys: sections.filter(s => s.key !== "").map(s => s.key)
    property string page: {
        const want = (Quickshell.env("SETTINGS_PAGE") || "").toLowerCase()
        for (const k of keys) if (k.toLowerCase() === want) return k
        return "General"
    }
    function step(d) {
        const i = keys.indexOf(page)
        page = keys[(i + d + keys.length) % keys.length]
    }

    // ---- lifecycle: open at start, quit after the close animation ----------------------------
    property bool showing: true
    property bool revealed: false     // the window is ready: the open animation may run
    function close() { showing = false }
    Binding { target: Pal; property: "open"; value: root.showing }
    Connections {
        target: Pal
        function onCloseRequested() { root.close() }
        function onNavigate(key) { if (root.keys.indexOf(key) >= 0) root.page = key }
    }
    // bin/settings: a second SUPER+comma closes the running panel
    IpcHandler {
        target: "settings"
        function close(): void { root.close() }
        function go(section: string): void {   // switch section (testing, scripts)
            const want = (section || "").toLowerCase()
            for (const k of root.keys) if (k.toLowerCase() === want) root.page = k
        }
    }

    PanelWindow {
        id: win
        screen: {
            const want = Quickshell.env("SETTINGS_SCREEN")
            const list = Quickshell.screens
            for (let i = 0; i < list.length; i++)
                if (list[i].name === want) return list[i]
            return list[0]
        }
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property real ui: Math.max(0.75, Math.min(1.25, height / 1200))
        Component.onCompleted: Pal.ui = ui
        onUiChanged: Pal.ui = ui

        // 0 = hidden, 1 = open; animates only once the window is ready
        property real shown: root.showing && root.revealed ? 1 : 0
        Behavior on shown {
            NumberAnimation { duration: root.showing ? 200 : 130; easing.type: Easing.OutCubic }
        }
        onShownChanged: if (!root.showing && shown === 0) Qt.quit()
        // Closed before it was ever shown: nothing to animate
        Connections {
            target: root
            function onShowingChanged() { if (!root.showing && !root.revealed) Qt.quit() }
        }

        // Ready = page loaded and 3 frames drawn, or 600 ms at most (a broken page must not
        // keep the panel hidden)
        property int frames: 0
        Connections {
            target: card.Window.window
            enabled: !root.revealed
            ignoreUnknownSignals: true
            function onFrameSwapped() {
                if (content.status === Loader.Ready && ++win.frames >= 3) root.revealed = true
            }
        }
        Timer {
            running: !root.revealed
            interval: 600
            onTriggered: root.revealed = true
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: Pal.dim * win.shown
        }
        MouseArea { anchors.fill: parent; onClicked: root.close() }

        Rectangle {
            id: card
            width: 920 * win.ui
            height: 640 * win.ui
            anchors.centerIn: parent
            radius: Pal.radiusLg
            color: Pal.window
            border.color: Pal.line
            border.width: 1
            clip: true
            // Prewarm: drawn but invisible until ready
            opacity: Math.max(win.shown, root.revealed ? 0 : 0.004)
            scale: 0.97 + 0.03 * win.shown

            MouseArea { anchors.fill: parent }   // clicks inside do not close

            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
                else if (event.key === Qt.Key_Down) { root.step(1); event.accepted = true }
                else if (event.key === Qt.Key_Up) { root.step(-1); event.accepted = true }
            }

            // ---- sidebar -------------------------------------------------------------------
            Rectangle {
                id: side
                width: 220 * win.ui
                height: parent.height
                color: Pal.sidebar
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Pal.line }

                Column {
                    x: 10 * win.ui
                    y: 18 * win.ui
                    width: parent.width - 20 * win.ui
                    spacing: 2 * win.ui

                    Text {
                        text: "Settings"
                        leftPadding: 8 * win.ui
                        bottomPadding: 10 * win.ui
                        color: Pal.text
                        font.family: Pal.font; font.pixelSize: 15 * win.ui; font.weight: Font.Bold
                    }
                    Repeater {
                        model: root.sections
                        Item {
                            required property var modelData
                            readonly property bool gap: modelData.key === ""
                            readonly property bool on: modelData.key === root.page
                            width: parent.width
                            height: gap ? 10 * win.ui : 32 * win.ui

                            Rectangle {
                                visible: !parent.gap
                                anchors.fill: parent
                                radius: Pal.radiusMd
                                color: parent.on ? Pal.primary : (a.containsMouse ? Pal.hover : "transparent")
                            }
                            Rectangle {   // colored icon tile
                                visible: !parent.gap
                                x: 8 * win.ui
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22 * win.ui; height: width
                                radius: Pal.radiusSm
                                color: parent.gap ? "transparent" : parent.modelData.color
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.parent.gap ? "" : parent.parent.modelData.glyph
                                    color: "#ffffff"
                                    font.family: Pal.icons; font.pixelSize: 12 * win.ui
                                }
                            }
                            Text {
                                visible: !parent.gap
                                x: 40 * win.ui
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.gap ? "" : parent.modelData.label
                                color: parent.on ? Pal.primaryFg : Pal.text
                                font.family: Pal.font; font.pixelSize: Pal.fs
                                font.weight: parent.on ? Font.DemiBold : Font.Normal
                            }
                            MouseArea {
                                id: a
                                anchors.fill: parent
                                enabled: !parent.gap
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.page = parent.modelData.key
                            }
                        }
                    }
                }
            }

            // ---- content -------------------------------------------------------------------
            Loader {
                id: content
                anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
                source: root.page + "Page.qml"
                // Built off the UI thread: the window and sidebar animate in at once instead of
                // freezing while a page (and its NetworkManager / PipeWire objects) loads
                asynchronous: true
                opacity: status === Loader.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                onStatusChanged: if (status === Loader.Error) console.warn("settings: cannot load", source)
            }
        }
    }
}
