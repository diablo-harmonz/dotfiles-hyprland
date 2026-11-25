// settings: macOS-style System Settings panel (bin/settings, SUPER+comma, the gear icon in
// Waybar). Started on demand and quits when closed, so it uses no memory or CPU otherwise.
//   sidebar      General (you and a quick status) / Wi-Fi, Bluetooth / Sound, Displays,
//                Battery / Storage, About / Appearance, Startup apps, Configs
//                (one file each: <Key>Page.qml)
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

    // key, label, Nerd Font glyph; "" = gap between sidebar groups
    readonly property var sections: [
        { key: "General",    label: "General",    glyph: "" },
        { key: "" },
        { key: "Network",    label: "Wi-Fi",      glyph: "" },
        { key: "Bluetooth",  label: "Bluetooth",  glyph: "" },
        { key: "" },
        { key: "Sound",      label: "Sound",      glyph: "" },
        { key: "Display",    label: "Displays",   glyph: "" },
        { key: "Power",      label: "Battery",    glyph: "" },
        { key: "" },
        { key: "Storage",    label: "Storage",    glyph: "" },
        { key: "System",     label: "About",      glyph: "" },
        { key: "" },
        { key: "Appearance", label: "Appearance", glyph: "󰏘" },
        { key: "Startup",    label: "Startup apps", glyph: "\uf135" },
        { key: "Configs",    label: "Configs",    glyph: "" }
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
    // Keyboard: a new page destroys the focused control of the old one, so the sidebar takes
    // the focus (otherwise no item would have it and every key would be lost)
    onPageChanged: if (!selftest) Qt.callLater(() => { if (cardRef) cardRef.forceActiveFocus() })
    property Item cardRef: null
    // Keyboard: from the sidebar into the first control of the page (→, Enter, Tab)
    function enterContent() {
        const first = card.nextItemInFocusChain(true)
        if (first && first !== card) first.forceActiveFocus(Qt.TabFocusReason)
    }

    // ---- self-test (QS_SELFTEST=1, run by bin/dotfiles-verify after updates) -----------------
    // No window is shown and nothing is scanned: every section is loaded once, each result is
    // logged as "SELFTEST <section> ok|error|timeout", then "SELFTEST done" and quit. QML errors
    // of a section show up in the log right before its line.
    readonly property bool selftest: (Quickshell.env("QS_SELFTEST") || "") !== ""
    property int testIndex: 0
    Timer {
        id: testTimer
        running: root.selftest
        interval: 100; repeat: true
        property int waited: 0
        onTriggered: {
            const st = content.status
            if (st === Loader.Loading && ++waited < 50) return     // 5 s at most per section
            console.info("SELFTEST", root.page, st === Loader.Ready ? "ok" : st === Loader.Error ? "error" : "timeout")
            waited = 0
            if (++root.testIndex >= root.keys.length) { console.info("SELFTEST done"); Qt.quit(); return }
            root.page = root.keys[root.testIndex]
        }
    }
    Component.onCompleted: if (selftest) page = keys[0]

    // ---- lifecycle: open at start, quit after the close animation ----------------------------
    property bool showing: !selftest
    property bool revealed: false     // the window is ready: the open animation may run
    function close() { showing = false }
    Binding { target: Pal; property: "open"; value: root.showing }
    Connections {
        target: Pal
        function onCloseRequested() { root.close() }
        function onNavigate(key) { if (root.keys.indexOf(key) >= 0) root.page = key }
        function onSidebarRequested() { card.forceActiveFocus() }
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
        WlrLayershell.keyboardFocus: root.selftest ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
        visible: !root.selftest

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
            Component.onCompleted: root.cardRef = card
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
                // The card itself has focus = the sidebar; keys a control did not use also
                // arrive here (Esc from a control: back to the sidebar)
                const inSidebar = card.activeFocus, k = event.key
                if (k === Qt.Key_Escape) {
                    if (inSidebar) root.close(); else card.forceActiveFocus()
                } else if (inSidebar && k === Qt.Key_Down) root.step(1)
                else if (inSidebar && k === Qt.Key_Up) root.step(-1)
                else if (inSidebar && (k === Qt.Key_Right || k === Qt.Key_Return || k === Qt.Key_Enter))
                    root.enterContent()
                else if (k >= Qt.Key_0 && k <= Qt.Key_9 && event.modifiers === Qt.NoModifier) {
                    const i = k === Qt.Key_0 ? 9 : k - Qt.Key_1     // 1..9, 0 = 10th section
                    if (i < root.keys.length) { root.page = root.keys[i]; card.forceActiveFocus() }
                } else return
                event.accepted = true
            }

            // ---- sidebar -------------------------------------------------------------------
            Rectangle {
                id: side
                width: 220 * win.ui
                height: parent.height
                color: Pal.hud ? "transparent" : Pal.sidebar

                // Keyboard hints at the bottom of the sidebar
                Text {
                    anchors.left: parent.left; anchors.leftMargin: (Pal.hud ? 26 : 18) * win.ui
                    anchors.bottom: parent.bottom; anchors.bottomMargin: (Pal.hud ? 30 : 16) * win.ui
                    width: parent.width - 2 * anchors.leftMargin
                    text: card.activeFocus ? "↑↓ section · 1–0 jump\n→ Enter Tab: into the page\nEsc: close"
                                           : "↑↓ Tab: next control\nEnter Space: press · ←→ adjust\nEsc: back to the sidebar"
                    lineHeight: 1.3
                    color: Pal.muted
                    opacity: 0.7
                    font.family: Pal.icons; font.pixelSize: 10 * win.ui
                }
                Rectangle {   // divider (HUD: inset, brighter)
                    anchors.right: parent.right
                    y: Pal.hud ? 24 * win.ui : 0
                    width: 1; height: parent.height - 2 * y
                    color: Pal.hud ? Pal.outline : Pal.line
                }

                Column {
                    // HUD: clear of the corner bracket
                    x: (Pal.hud ? 18 : 10) * win.ui
                    y: (Pal.hud ? 34 : 18) * win.ui
                    width: parent.width - 2 * x
                    spacing: 2 * win.ui

                    Text {
                        text: Pal.label("Settings")
                        leftPadding: 8 * win.ui
                        bottomPadding: 10 * win.ui
                        color: Pal.text
                        font.family: Pal.font; font.pixelSize: 15 * win.ui
                        font.weight: Pal.hud ? Font.Light : Font.Bold
                        font.letterSpacing: Pal.hud ? 4 * win.ui : 0
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
                                color: parent.on && !Pal.hud ? Pal.primary : (a.containsMouse ? Pal.hover : "transparent")
                                // keyboard in the sidebar: a ring on the chosen section
                                border.width: parent.on && card.activeFocus ? 2 : (parent.on && Pal.hud ? 1 : 0)
                                border.color: parent.on && card.activeFocus ? Pal.text : Pal.outlineHot
                            }
                            Rectangle {   // HUD: a line from the chosen section across to the content
                                visible: Pal.hud && parent.on
                                anchors.left: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18 * win.ui + 28 * win.ui   // the sidebar margin + into the content
                                height: 1
                                color: Pal.outlineHot
                            }
                            Rectangle {   // colored icon tile
                                visible: !parent.gap
                                x: 8 * win.ui
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22 * win.ui; height: width
                                radius: Pal.radiusSm
                                // A plain flat glyph, no coloured tile (both looks); on the chosen
                                // row of the mac look it takes the accent's text colour
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.parent.gap ? "" : parent.parent.modelData.glyph
                                    color: parent.parent.on && !Pal.hud ? Pal.primaryFg
                                         : (parent.parent.on ? Pal.text : Pal.muted)
                                    font.family: Pal.icons; font.pixelSize: 14 * win.ui
                                }
                            }
                            Text {
                                visible: !parent.gap
                                x: 40 * win.ui
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.gap ? "" : parent.modelData.label
                                color: parent.on && !Pal.hud ? Pal.primaryFg : Pal.text
                                font.family: Pal.font; font.pixelSize: Pal.fs
                                font.weight: parent.on && !Pal.hud ? Font.DemiBold : Font.Normal
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

            // ---- HUD corner brackets (top left, bottom right) ---------------------------------
            component Bracket: Item {
                property bool flip: false
                width: 30 * win.ui; height: width
                Rectangle { x: parent.flip ? parent.width - width : 0; y: parent.flip ? parent.height - 2 : 0
                            width: parent.width; height: 2; color: Pal.outlineHot }
                Rectangle { x: parent.flip ? parent.width - 2 : 0; y: 0
                            width: 2; height: parent.height; color: Pal.outlineHot }
            }
            Bracket { visible: Pal.hud; x: 8 * win.ui; y: 8 * win.ui; z: 10 }
            Bracket { visible: Pal.hud; flip: true; z: 10
                      x: card.width - width - 8 * win.ui; y: card.height - height - 8 * win.ui }

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
