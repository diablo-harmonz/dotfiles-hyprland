// colorpicker: choose the theme pack and the desktop colors (SUPER+C; bin/theme, bin/colors).
// Run on demand, quits after a choice, so it uses no memory while closed.
//   Tab / t       theme pack (its wallpaper, lock screen, borders...; bin/theme)
//   ← → / h l     color: the wallpaper's own ones, then the presets
//   ↑ ↓ / k j     style (Matugen scheme)
//   #             type a color (Enter takes it)
//   Enter         apply            A   back to auto (the wallpaper's main color)
//   Esc / click outside / SUPER+C   close without changing anything
// The panel itself is drawn in the colors being previewed (`colors preview`, nothing is
// written until Enter), so what you see is what the desktop will get. With another theme
// picked, the wallpaper colors are those of the wallpaper that theme would show.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property var presets: [
        "#5b8def", "#3fb6c6", "#4caf7a", "#a3be5c", "#e0b84f",
        "#e58a4b", "#e06c75", "#d46ba6", "#9b7be0", "#8a93a6"
    ]
    readonly property var schemes: [
        { id: "tonal-spot", name: "Tonal" },     { id: "vibrant", name: "Vibrant" },
        { id: "expressive", name: "Expressive" }, { id: "neutral", name: "Neutral" },
        { id: "monochrome", name: "Mono" },      { id: "fidelity", name: "Fidelity" },
        { id: "content", name: "Content" },      { id: "rainbow", name: "Rainbow" },
        { id: "fruit-salad", name: "Fruit salad" }
    ]

    // ---- state -------------------------------------------------------------------------
    property var themes: []              // from `theme list-tsv`: { name, desc, wall }
    property string theme: ""
    property string savedTheme: ""
    readonly property int themeIndex: {
        for (let i = 0; i < themes.length; i++) if (themes[i].name === theme) return i
        return -1
    }
    readonly property string themeWall: themeIndex >= 0 ? themes[themeIndex].wall : ""
    property var wallColors: []          // from `colors candidates`
    property string source: ""           // "wallpaper:N" or "#rrggbb"
    property string scheme: "tonal-spot"
    property string savedSource: ""
    property string savedScheme: ""
    property bool loaded: false
    property var pv: ({                  // preview palette (`colors preview`)
        primary: "#adc7ff", on_primary: "#0f2f60", secondary: "#bfc6dc", tertiary: "#debcdf",
        primary_container: "#284777", surface: "#111318", surface_container: "#1d2024",
        surface_container_high: "#282a2f", on_surface: "#e2e2e9", on_surface_variant: "#c4c6d0",
        outline_variant: "#44474e", error: "#ffb4ab"
    })

    // Every color option in order: wallpaper ones, presets, then a typed one if any
    readonly property var options: {
        const o = []
        for (let i = 0; i < wallColors.length; i++) o.push({ src: "wallpaper:" + i, color: wallColors[i] })
        for (const c of presets) o.push({ src: c, color: c })
        if (source.startsWith("#") && presets.indexOf(source) < 0) o.push({ src: source, color: source })
        return o
    }
    readonly property int optionIndex: {
        for (let i = 0; i < options.length; i++) if (options[i].src === source) return i
        return -1
    }
    readonly property int schemeIndex: {
        for (let i = 0; i < schemes.length; i++) if (schemes[i].id === scheme) return i
        return 0
    }

    function moveColor(step) {
        if (options.length === 0) return
        const i = optionIndex < 0 ? 0 : Math.max(0, Math.min(options.length - 1, optionIndex + step))
        source = options[i].src
    }
    function moveScheme(step) {
        scheme = schemes[(schemeIndex + step + schemes.length) % schemes.length].id
    }
    function moveTheme(step) {
        if (themes.length === 0) return
        theme = themes[(Math.max(0, themeIndex) + step + themes.length) % themes.length].name
    }
    // A new theme recolors by itself (its wallpaper), so the color choice is only saved
    // before it; without one the colors are made right away
    function commit(src, sch) {
        const bin = "$HOME/.local/bin/"
        if (theme !== "" && theme !== savedTheme)
            Quickshell.execDetached(["sh", "-c", "\"" + bin + "colors\" save \"$1\" \"$2\" && exec \"" + bin
                                     + "theme\" apply \"$3\"", "sh", src, sch, theme])
        else if (src !== savedSource || sch !== savedScheme)
            Quickshell.execDetached(["sh", "-c", "exec \"" + bin + "colors\" set \"$1\" \"$2\"", "sh", src, sch])
        win.close()
    }
    function apply() {
        if (loaded && source !== "") commit(source, scheme)
    }
    function auto() {   // the defaults of bin/colors
        if (loaded) commit("wallpaper:0", "tonal-spot")
    }
    function loadCandidates() {
        candidates.exec(["sh", "-c", "exec \"$HOME/.local/bin/colors\" candidates \"$1\"", "sh", themeWall])
    }

    onSourceChanged: previewTimer.restart()
    onSchemeChanged: previewTimer.restart()
    onThemeWallChanged: { loadCandidates(); previewTimer.restart() }

    Timer {
        id: previewTimer
        interval: 40
        onTriggered: if (root.source !== "")
            preview.exec(["sh", "-c", "exec \"$HOME/.local/bin/colors\" preview \"$1\" \"$2\" \"$3\"", "sh",
                          root.source, root.scheme, root.themeWall])
    }
    Process {
        id: preview
        stdout: StdioCollector {
            onStreamFinished: {
                try { const p = JSON.parse(text); if (p.primary) root.pv = p } catch (e) {}
            }
        }
    }
    Process {
        running: true
        command: ["sh", "-c", "exec \"$HOME/.local/bin/colors\" status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/)
                root.savedSource = f[0] || "wallpaper:0"
                root.savedScheme = f[1] || "tonal-spot"
                root.scheme = root.savedScheme
                root.source = root.savedSource
                if (root.source.startsWith("#")) hex.text = root.source
                root.loaded = true
            }
        }
    }
    Process {
        id: candidates
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallColors = text.split("\n").filter(s => /^#[0-9a-fA-F]{6}$/.test(s))
                // That wallpaper has fewer colors: take its first
                const m = /^wallpaper:(\d+)$/.exec(root.source)
                if (m && root.wallColors.length > 0 && +m[1] >= root.wallColors.length)
                    root.source = "wallpaper:0"
            }
        }
    }
    Process {
        running: true
        command: ["sh", "-c", "exec \"$HOME/.local/bin/theme\" list-tsv"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = []
                let active = ""
                for (const line of text.split("\n")) {
                    const f = line.split("\t")
                    if (f.length < 4) continue
                    t.push({ name: f[0], desc: f[1], wall: f[2] })
                    if (f[3] === "1") active = f[0]
                }
                root.themes = t
                root.savedTheme = active
                root.theme = active
                if (root.themeWall === "") root.loadCandidates()   // no pack: the current wallpaper
            }
        }
    }

    PanelWindow {
        id: win
        screen: {
            const want = Quickshell.env("COLORPICKER_SCREEN")
            const list = Quickshell.screens
            for (let i = 0; i < list.length; i++)
                if (list[i].name === want) return list[i]
            return list[0]
        }
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "colorpicker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        readonly property real ui: height / 1200
        property bool closing: false
        property real shown: 0

        NumberAnimation on shown { from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { id: outro; target: win; property: "shown"; to: 0; duration: 140
                          onFinished: Qt.quit() }
        function close() { if (!closing) { closing = true; outro.start() } }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.35 * win.shown
        }
        MouseArea { anchors.fill: parent; onClicked: win.close() }

        // ---- the panel -----------------------------------------------------------------
        Rectangle {
            id: card
            width: 640 * win.ui
            height: body.implicitHeight + 2 * pad
            anchors.centerIn: parent
            readonly property real pad: 28 * win.ui
            radius: 14 * win.ui
            color: Qt.alpha(root.pv.surface, 0.94)
            border.color: root.pv.outline_variant
            border.width: Math.max(1, 1 * win.ui)
            opacity: win.shown
            transform: Translate { y: (1 - win.shown) * 20 * win.ui }
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            MouseArea { anchors.fill: parent }   // clicks inside do not close

            focus: true
            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Left: case Qt.Key_H:  root.moveColor(-1); break
                case Qt.Key_Right: case Qt.Key_L: root.moveColor(1); break
                case Qt.Key_Up: case Qt.Key_K:    root.moveScheme(-1); break
                case Qt.Key_Down: case Qt.Key_J:  root.moveScheme(1); break
                case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: root.apply(); break
                case Qt.Key_Tab: case Qt.Key_T: root.moveTheme(1); break
                case Qt.Key_Backtab: root.moveTheme(-1); break
                case Qt.Key_A: root.auto(); break
                case Qt.Key_NumberSign: hex.forceActiveFocus(); hex.selectAll(); break
                case Qt.Key_Escape: case Qt.Key_Q: win.close(); break
                default: return
                }
                event.accepted = true
            }

            Column {
                id: body
                x: card.pad; y: card.pad
                width: card.width - 2 * card.pad
                spacing: 18 * win.ui

                // Title
                Item {
                    width: parent.width; height: title.height
                    Text {
                        id: title
                        text: "Theme & colors"
                        color: root.pv.on_surface
                        font.family: "FiraCode Nerd Font"; font.pixelSize: 20 * win.ui; font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: title.verticalCenter
                        text: (root.theme !== root.savedTheme ? "theme " + root.theme + " · " : "")
                              + (root.source.startsWith("wallpaper") ? "from the wallpaper" : "fixed color")
                        color: root.pv.on_surface_variant
                        font.family: "FiraCode Nerd Font"; font.pixelSize: 13 * win.ui
                    }
                }

                // Theme packs
                Column {
                    spacing: 8 * win.ui
                    width: parent.width
                    visible: root.themes.length > 0
                    Text {
                        text: "Theme"
                        color: root.pv.on_surface_variant
                        font.family: "FiraCode Nerd Font"; font.pixelSize: 12 * win.ui
                    }
                    Flow {
                        width: parent.width
                        spacing: 8 * win.ui
                        Repeater {
                            model: root.themes
                            Chip {
                                required property var modelData
                                label: modelData.name.charAt(0).toUpperCase() + modelData.name.slice(1)
                                on: modelData.name === root.theme
                                onPicked: root.theme = modelData.name
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.themeIndex >= 0 ? root.themes[root.themeIndex].desc : ""
                        color: root.pv.on_surface_variant
                        font.family: "FiraCode Nerd Font"; font.pixelSize: 12 * win.ui
                    }
                }

                // Rows of swatches
                Repeater {
                    model: [
                        { label: "Wallpaper", from: 0, count: root.wallColors.length },
                        { label: "Presets", from: root.wallColors.length, count: root.presets.length }
                    ]
                    Column {
                        required property var modelData
                        spacing: 8 * win.ui
                        Text {
                            text: modelData.label
                            color: root.pv.on_surface_variant
                            font.family: "FiraCode Nerd Font"; font.pixelSize: 12 * win.ui
                        }
                        Row {
                            spacing: 10 * win.ui
                            Repeater {
                                model: modelData.count
                                Swatch {
                                    required property int index
                                    option: root.options[modelData.from + index]
                                }
                            }
                            Text {
                                visible: modelData.count === 0
                                text: "Loading..."
                                color: root.pv.on_surface_variant
                                font.family: "FiraCode Nerd Font"; font.pixelSize: 13 * win.ui
                            }
                        }
                    }
                }

                // Typed color
                Row {
                    spacing: 10 * win.ui
                    Swatch {
                        visible: root.source.startsWith("#") && root.presets.indexOf(root.source) < 0
                        option: visible ? root.options[root.options.length - 1] : null
                    }
                    Rectangle {
                        width: 150 * win.ui; height: 34 * win.ui
                        radius: 8 * win.ui
                        color: root.pv.surface_container_high
                        border.color: hex.activeFocus ? root.pv.primary : root.pv.outline_variant
                        border.width: Math.max(1, 1 * win.ui)
                        TextInput {
                            id: hex
                            anchors.fill: parent
                            anchors.leftMargin: 12 * win.ui
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.pv.on_surface
                            selectionColor: root.pv.primary
                            selectedTextColor: root.pv.on_primary
                            font.family: "FiraCode Nerd Font"; font.pixelSize: 14 * win.ui
                            maximumLength: 7
                            validator: RegularExpressionValidator { regularExpression: /#?[0-9a-fA-F]{0,6}/ }
                            Text {
                                visible: !hex.text && !hex.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                                text: "# type a color"
                                color: root.pv.on_surface_variant
                                font: hex.font
                            }
                            Keys.onReturnPressed: take()
                            Keys.onEnterPressed: take()
                            Keys.onEscapePressed: card.forceActiveFocus()
                            function take() {
                                let t = text.trim()
                                if (!t.startsWith("#")) t = "#" + t
                                if (/^#[0-9a-fA-F]{6}$/.test(t)) {
                                    text = t.toLowerCase()
                                    root.source = text
                                }
                                card.forceActiveFocus()
                            }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Enter to preview"
                        visible: hex.activeFocus
                        color: root.pv.on_surface_variant
                        font.family: "FiraCode Nerd Font"; font.pixelSize: 12 * win.ui
                    }
                }

                // Styles
                Column {
                    spacing: 8 * win.ui
                    width: parent.width
                    Text {
                        text: "Style"
                        color: root.pv.on_surface_variant
                        font.family: "FiraCode Nerd Font"; font.pixelSize: 12 * win.ui
                    }
                    Flow {
                        width: parent.width
                        spacing: 8 * win.ui
                        Repeater {
                            model: root.schemes
                            Chip {
                                required property var modelData
                                label: modelData.name
                                on: modelData.id === root.scheme
                                onPicked: root.scheme = modelData.id
                            }
                        }
                    }
                }

                // Preview: the colors the desktop will get
                Row {
                    width: parent.width
                    spacing: 6 * win.ui
                    Repeater {
                        model: ["primary", "secondary", "tertiary", "primary_container",
                                "surface_container_high", "on_surface"]
                        Rectangle {
                            required property string modelData
                            width: (body.width - 5 * 6 * win.ui) / 6
                            height: 26 * win.ui
                            radius: 6 * win.ui
                            color: root.pv[modelData]
                            border.color: root.pv.outline_variant
                            border.width: Math.max(1, 1 * win.ui)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                // Keys
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Tab theme   ←→ color   ↑↓ style   # type   Enter apply   A auto   Esc"
                    color: root.pv.on_surface_variant
                    font.family: "FiraCode Nerd Font"; font.pixelSize: 12 * win.ui
                }
            }
        }
    }

    // A pill button (themes, styles); the chosen one is filled
    component Chip: Rectangle {
        id: chipRoot
        property string label
        property bool on: false
        signal picked()
        width: chipText.implicitWidth + 24 * win.ui
        height: 30 * win.ui
        radius: height / 2
        color: on ? root.pv.primary : root.pv.surface_container_high
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chipRoot.label
            color: chipRoot.on ? root.pv.on_primary : root.pv.on_surface
            font.family: "FiraCode Nerd Font"; font.pixelSize: 13 * win.ui
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { chipRoot.picked(); card.forceActiveFocus() }
        }
    }

    // A round color button; the chosen one gets a ring
    component Swatch: Item {
        property var option: null
        readonly property bool on: !!option && option.src === root.source
        width: 34 * win.ui; height: width
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: root.pv.on_surface
            border.width: 2 * win.ui
            opacity: parent.on ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 8 * win.ui; height: width
            radius: width / 2
            color: parent.option ? parent.option.color : "transparent"
            border.color: Qt.alpha("#ffffff", 0.15)
            border.width: 1
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!parent.option) return
                if (parent.on) root.apply()   // clicking the chosen one again applies it
                else root.source = parent.option.src
                card.forceActiveFocus()
            }
        }
    }
}
