// Appearance (settings appearance): the wallpaper (bin/wallpaper), the desktop colors (bin/colors, Matugen:
// wallpaper colors, presets or your own, and the style) and the theme pack (bin/theme:
// wallpaper, lock screen, borders, Waybar...). A color click recolors the whole desktop.
import QtQuick
import Quickshell
import Quickshell.Io

Page {
    id: p
    title: "Appearance"

    property var themes: []           // { name, desc, wall, active }
    property string colorSource: ""
    property string colorScheme: ""
    property string wall: ""
    property int stamp: 0             // bumps the wallpaper image after a change
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function refresh() { st.running = false; st.running = true }
    function cap(s) { return s ? s.charAt(0).toUpperCase() + s.slice(1).replace(/-/g, " ") : "" }

    Process {
        id: st
        running: true
        command: ["sh", "-c",
            "\"$HOME/.local/bin/theme\" list-tsv | sed 's/^/T\\t/';" +
            "printf 'C\\t%s\\n' \"$(\"$HOME/.local/bin/colors\" status)\";" +
            "printf 'W\\t%s\\n' \"$(readlink -f \"$HOME/.cache/wallpaper/current\")\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = []
                for (const l of text.split("\n")) {
                    const f = l.split("\t")
                    if (f[0] === "T" && f.length >= 5) t.push({ name: f[1], desc: f[2], wall: f[3], active: f[4] === "1" })
                    else if (f[0] === "C") { const c = (f[1] || "").split(" "); p.colorSource = c[0] || ""; p.colorScheme = c[1] || "" }
                    else if (f[0] === "W") { if (f[1] !== p.wall) p.stamp++; p.wall = f[1] || "" }
                }
                p.themes = t
            }
        }
    }
    Timer { interval: 2500; running: Pal.open; repeat: true; onTriggered: p.refresh() }
    onReopened: refresh()

    Group {
        title: "Wallpaper"
        Item {
            width: parent.width
            height: 150 * Pal.ui
            Rectangle {
                id: frame
                x: Pal.pad; y: Pal.pad
                width: 210 * Pal.ui; height: parent.height - 2 * Pal.pad
                radius: Pal.radiusMd
                color: Pal.line
                clip: true
                Image {
                    anchors.fill: parent
                    source: p.wall ? "file://" + p.wall + "?" + p.stamp : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 420
                }
            }
            Column {
                anchors.left: frame.right; anchors.leftMargin: 16 * Pal.ui
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - frame.width - 3 * Pal.pad
                spacing: 10 * Pal.ui
                Text {
                    width: parent.width
                    text: p.wall ? p.wall.split("/").pop() : "No wallpaper"
                    elide: Text.ElideMiddle
                    color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs
                }
                Text {
                    text: "Colors follow the wallpaper (Matugen)"
                    color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
                }
                Row {
                    spacing: 8 * Pal.ui
                    Btn { text: "Choose…"; accent: true; onClicked: { p.run("\"" + p.bin + "wallpaper\" select"); Pal.closeRequested() } }
                    Btn { text: "Random"; onClicked: p.run("\"" + p.bin + "wallpaper\" random") }
                }
            }
        }
    }

    // ---- colors (bin/colors): where Matugen starts from, and the style ---------------------
    readonly property var presets: ["#5b8def", "#3fb6c6", "#4caf7a", "#a3be5c", "#e0b84f",
                                    "#e58a4b", "#e06c75", "#d46ba6", "#9b7be0", "#8a93a6"]
    readonly property var schemes: [
        { key: "tonal-spot", label: "Tonal" },      { key: "vibrant", label: "Vibrant" },
        { key: "expressive", label: "Expressive" }, { key: "neutral", label: "Neutral" },
        { key: "monochrome", label: "Mono" },       { key: "fidelity", label: "Fidelity" },
        { key: "content", label: "Content" },       { key: "rainbow", label: "Rainbow" },
        { key: "fruit-salad", label: "Fruit salad" }
    ]
    property var wallColors: []
    property bool applying: false
    function setColors(src, scheme) {
        if (applying) return
        applying = true
        p.colorSource = src; p.colorScheme = scheme      // shown at once; the desktop follows
        setProc.command = ["sh", "-c", "exec \"$HOME/.local/bin/colors\" set \"$1\" \"$2\"", "sh", src, scheme]
        setProc.running = true
    }
    Process {
        id: setProc
        onExited: { p.applying = false; p.refresh() }
    }
    Process {   // the colors found in the current wallpaper
        id: candProc
        command: ["sh", "-c", "exec \"$HOME/.local/bin/colors\" candidates"]
        stdout: StdioCollector {
            onStreamFinished: p.wallColors = text.split("\n").filter(c => /^#[0-9a-fA-F]{6}$/.test(c))
        }
    }
    onWallChanged: { candProc.running = false; candProc.running = true }

    component Swatch: Rectangle {
        property string src: ""
        property color fill: "transparent"
        readonly property bool on: p.colorSource === src
        width: 24 * Pal.ui; height: width; radius: width / 2
        color: fill
        border.color: on ? Pal.text : Pal.line
        border.width: on ? 2 : 1
        Rectangle {   // a ring around the chosen one
            visible: parent.on
            anchors.centerIn: parent
            width: parent.width + 6 * Pal.ui; height: width; radius: width / 2
            color: "transparent"; border.color: Pal.primary; border.width: 2
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: p.setColors(parent.src, p.colorScheme || "tonal-spot")
        }
    }

    Group {
        title: "Color"
        footer: "The whole desktop takes its colors from this (Matugen). Wallpaper colors follow the wallpaper; a preset or your own color stays when the wallpaper changes."
        Item {
            width: parent.width
            height: colorCol.implicitHeight + 2 * Pal.pad
            Column {
                id: colorCol
                x: Pal.pad; y: Pal.pad
                width: parent.width - 2 * Pal.pad
                spacing: 12 * Pal.ui

                Text {
                    text: "From the wallpaper"
                    color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
                }
                Row {
                    spacing: 12 * Pal.ui
                    Repeater {
                        model: p.wallColors
                        Swatch { required property var modelData; required property int index
                                 src: "wallpaper:" + index; fill: modelData }
                    }
                    Text {
                        visible: p.wallColors.length === 0
                        text: "Reading the wallpaper…"
                        color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
                    }
                }
                Text {
                    text: "Presets"
                    color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
                }
                Row {
                    spacing: 12 * Pal.ui
                    Repeater {
                        model: p.presets
                        Swatch { required property var modelData; src: modelData; fill: modelData }
                    }
                }
                Row {
                    spacing: 8 * Pal.ui
                    Rectangle {
                        width: 130 * Pal.ui; height: 26 * Pal.ui
                        radius: Pal.radiusSm
                        color: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.08)
                        border.color: hex.activeFocus ? Pal.primary : Pal.line
                        TextInput {
                            id: hex
                            anchors.fill: parent
                            anchors.leftMargin: 8 * Pal.ui; anchors.rightMargin: 8 * Pal.ui
                            verticalAlignment: TextInput.AlignVCenter
                            maximumLength: 7
                            color: Pal.text; selectionColor: Pal.primary
                            font.family: Pal.icons; font.pixelSize: Pal.fs
                            readonly property bool valid: /^#?[0-9a-fA-F]{6}$/.test(text)
                            Keys.onReturnPressed: useHex.clicked()
                            Text {
                                visible: hex.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "#rrggbb"
                                color: Pal.muted; font.family: Pal.icons; font.pixelSize: Pal.fs
                            }
                        }
                    }
                    Btn {
                        id: useHex
                        text: "Use this color"
                        enabled: hex.valid
                        onClicked: if (hex.valid) p.setColors("#" + hex.text.replace("#", "").toLowerCase(), p.colorScheme || "tonal-spot")
                    }
                }
            }
        }
        SRow {
            title: "Style"
            subtitle: p.applying ? "Applying…" : "How strongly the color is used"
            Btn {
                text: "Auto"
                onClicked: p.setColors("wallpaper:0", "tonal-spot")
            }
        }
        Item {
            width: parent.width
            height: styleFlow.implicitHeight + Pal.pad
            Flow {
                id: styleFlow
                x: Pal.pad
                width: parent.width - 2 * Pal.pad
                spacing: 6 * Pal.ui
                Repeater {
                    model: p.schemes
                    Btn {
                        required property var modelData
                        text: modelData.label
                        accent: p.colorScheme === modelData.key
                        onClicked: p.setColors(p.colorSource || "wallpaper:0", modelData.key)
                    }
                }
            }
        }
    }

    Group {
        title: "Theme"
        footer: "A theme pack changes the wallpaper, lock screen, window borders, Waybar and fastfetch together."
        Repeater {
            model: p.themes
            SRow {
                required property var modelData
                clickable: !modelData.active
                icon: modelData.active ? "" : ""
                iconColor: Pal.primary
                title: p.cap(modelData.name)
                subtitle: modelData.desc
                onClicked: { p.run("\"" + p.bin + "theme\" apply \"" + modelData.name + "\"") }
                Text {
                    visible: modelData.active
                    anchors.verticalCenter: parent.verticalCenter
                    text: "In use"; color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
                }
                Btn {
                    visible: !modelData.active
                    text: "Apply"
                    onClicked: p.run("\"" + p.bin + "theme\" apply \"" + modelData.name + "\"")
                }
            }
        }
    }
}
