// Displays: screen brightness, keyboard backlight, night light (hyprsunset), the screens in
// use, and the external monitor mode (bin/display-toggle: mirror / extend / off).
import QtQuick
import Quickshell
import Quickshell.Io

Page {
    id: p
    title: "Displays"

    property real brightness: 0          // 0..1
    property int kbd: -1                 // keyboard backlight 0..kbdMax, -1 = none
    property int kbdMax: 2
    property int temp: 6000              // hyprsunset temperature; >= 6000 = off
    property var monitors: []
    property string mode: ""             // display-toggle state: mirror / extend / off
    readonly property bool external: monitors.some(m => !m.name.startsWith("eDP"))
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function refresh() { info.running = false; info.running = true }

    // Brightness is written while dragging: a short timer keeps it to ~20 writes a second
    property real wantBrightness: -1
    Timer {
        id: bTimer; interval: 50
        onTriggered: if (p.wantBrightness >= 0)
            p.run("brightnessctl -q -c backlight set " + Math.max(1, Math.round(p.wantBrightness * 100)) + "%")
    }

    Process {
        id: info
        running: true
        command: ["sh", "-c",
            "printf 'B %s\\n' \"$(brightnessctl -m -c backlight | cut -d, -f4 | tr -d %)\";" +
            "k=$(brightnessctl -m -d '*kbd_backlight*' 2>/dev/null) && printf 'K %s %s\\n' \"$(echo \"$k\" | cut -d, -f3)\" \"$(echo \"$k\" | cut -d, -f5)\";" +
            "printf 'T %s\\n' \"$(hyprctl hyprsunset temperature 2>/dev/null)\";" +
            "printf 'S %s\\n' \"$(cat \"${XDG_RUNTIME_DIR:-/tmp}/display-toggle.state\" 2>/dev/null)\";" +
            "printf 'M %s\\n' \"$(hyprctl monitors -j | jq -c '[.[] | {name, description, width, height, refreshRate, scale}]')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const k = line.charAt(0), v = line.substr(2).trim()
                    if (k === "B" && v !== "") p.brightness = (+v) / 100
                    else if (k === "K") { const f = v.split(" "); p.kbd = +f[0]; p.kbdMax = +f[1] || 2 }
                    else if (k === "T" && /^\d+$/.test(v)) p.temp = +v
                    else if (k === "S") p.mode = v
                    else if (k === "M") { try { p.monitors = JSON.parse(v) } catch (e) {} }
                }
            }
        }
    }
    Timer { interval: 3000; running: Pal.open; repeat: true; onTriggered: p.refresh() }
    onReopened: refresh()

    Group {
        title: "Brightness"
        SRow {
            icon: ""; title: "Display"
            Sld {
                anchors.verticalCenter: parent.verticalCenter
                width: 260 * Pal.ui
                value: p.brightness
                onMoved: v => { p.brightness = v; p.wantBrightness = v; bTimer.restart() }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 40 * Pal.ui; horizontalAlignment: Text.AlignRight
                text: Math.round(p.brightness * 100) + " %"
                color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
            }
        }
        SRow {
            visible: p.kbd >= 0
            icon: ""; title: "Keyboard backlight"
            Seg {
                options: p.kbdMax >= 2 ? [{ key: "0", label: "Off" }, { key: "1", label: "Low" }, { key: "2", label: "High" }]
                                       : [{ key: "0", label: "Off" }, { key: "1", label: "On" }]
                current: String(p.kbd)
                onPicked: k => { p.kbd = +k; p.run("brightnessctl -q -d '*kbd_backlight*' set " + k) }
            }
        }
    }

    Group {
        title: "Night light"
        footer: "Warm colors in the evening: on by itself from 19:00 to 6:30 (hypr/hyprsunset.conf). The switch overrides it until the next change."
        SRow {
            icon: ""; title: "Night light"
            subtitle: p.temp < 6000 ? p.temp + " K" : "Off"
            Toggle {
                checked: p.temp < 6000
                onToggled: v => {
                    p.temp = v ? 4500 : 6000
                    p.run(v ? "hyprctl hyprsunset temperature 4500" : "hyprctl hyprsunset identity")
                }
            }
        }
        SRow {
            visible: p.temp < 6000
            title: "Warmth"
            Sld {
                anchors.verticalCenter: parent.verticalCenter
                width: 260 * Pal.ui
                // 6000 K (cool) .. 3000 K (warm)
                value: (6000 - p.temp) / 3000
                onMoved: v => { p.temp = Math.round((6000 - v * 3000) / 100) * 100
                                p.run("hyprctl hyprsunset temperature " + Math.min(5900, p.temp)) }
            }
            Item { width: 40 * Pal.ui; height: 1 }
        }
    }

    Group {
        title: "Screens"
        Repeater {
            model: p.monitors
            SRow {
                required property var modelData
                icon: modelData.name.startsWith("eDP") ? "" : ""
                title: modelData.name.startsWith("eDP") ? "Built-in display" : (modelData.description || modelData.name)
                subtitle: modelData.width + " × " + modelData.height + " · " + Math.round(modelData.refreshRate)
                          + " Hz · scale " + (+modelData.scale).toFixed(2).replace(/\.?0+$/, "") + " · " + modelData.name
            }
        }
    }

    Group {
        title: "External monitor"
        visible: p.external
        footer: "Also Fn+F7. Closing the lid with a monitor plugged in leaves only the monitor on."
        SRow {
            icon: ""; title: "Mode"
            Seg {
                options: [{ key: "mirror", label: "Mirror" }, { key: "extend", label: "Extend" }, { key: "off", label: "Off" }]
                current: p.mode === "" ? "extend" : p.mode
                onPicked: k => { p.mode = k; p.run("\"" + p.bin + "display-toggle\" " + k) }
            }
        }
    }
}
