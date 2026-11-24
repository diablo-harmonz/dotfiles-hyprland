// Appearance: the theme pack (bin/theme: wallpaper, lock screen, borders, Waybar...), the
// wallpaper (bin/wallpaper) and the desktop colors (bin/colors, Matugen).
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
                radius: 8 * Pal.ui
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

    Group {
        title: "Colors"
        SRow {
            icon: "\u{F03D8}"; iconColor: Pal.primary
            title: p.colorSource.startsWith("#") ? "Fixed color " + p.colorSource
                   : p.colorSource ? "From the wallpaper" + (p.colorSource !== "wallpaper:0" ? " (color " + (+p.colorSource.split(":")[1] + 1) + ")" : "") : ""
            subtitle: p.colorScheme ? "Style: " + p.cap(p.colorScheme) : ""
            Row {
                spacing: 4 * Pal.ui
                anchors.verticalCenter: parent.verticalCenter
                Repeater {
                    model: [Pal.primary, Pal.surface, Pal.text, Pal.urgent]
                    Rectangle {
                        required property var modelData
                        width: 16 * Pal.ui; height: width; radius: width / 2
                        color: modelData; border.color: Pal.line
                    }
                }
            }
            Btn { text: "Change…"; onClicked: { p.run("\"" + p.bin + "colors\""); Pal.closeRequested() } }
        }
    }

    Group {
        title: "Theme"
        footer: "A theme pack changes the wallpaper, lock screen, window borders, Waybar and fastfetch together. Also SUPER+C."
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
