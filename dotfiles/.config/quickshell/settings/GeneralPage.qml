// General: who you are (picture from ~/.face, else your initial; full name from the passwd
// comment field, else the user name) and a quick status of this computer. Light on purpose:
// it reads everything with a few small commands (2-20 ms each) instead of starting the
// NetworkManager / BlueZ / PipeWire / UPower modules, so opening Settings stays cheap.
// Each status row opens its section.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Page {
    id: p
    title: "General"

    readonly property string home: Quickshell.env("HOME")
    property var info: ({})
    property int stamp: 0                      // reloads the picture after it changes

    function refresh() { st.running = false; st.running = true }
    function value(k, fallback) { return p.info[k] !== undefined && p.info[k] !== "" ? p.info[k] : fallback }

    Process {
        id: st
        running: true
        command: ["sh", "-c",
            "u=$(id -un); printf 'user\\t%s\\n' \"$u\";" +
            "printf 'name\\t%s\\n' \"$(getent passwd \"$u\" | cut -d: -f5 | cut -d, -f1)\";" +
            "printf 'face\\t%s\\n' \"$([ -f \"$HOME/.face\" ] && echo \"$HOME/.face\")\";" +
            "printf 'host\\t%s\\n' \"$(cat /etc/hostname 2>/dev/null || uname -n)\";" +
            "printf 'model\\t%s\\n' \"$(cat /sys/class/dmi/id/product_version 2>/dev/null)\";" +
            "printf 'up\\t%s\\n' \"$(uptime -p | sed 's/^up //')\";" +
            "printf 'net\\t%s\\n' \"$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -E ':(802-11-wireless|802-3-ethernet)$' | head -1)\";" +
            "printf 'bt\\t%s\\n' \"$(bluetoothctl show 2>/dev/null | sed -n 's/.*Powered: //p' | head -1)\";" +
            "printf 'btdev\\t%s\\n' \"$(bluetoothctl devices Connected 2>/dev/null | cut -d' ' -f3- | paste -sd, | sed 's/,/, /g')\";" +
            "printf 'vol\\t%s\\n' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)\";" +
            "printf 'bright\\t%s\\n' \"$(brightnessctl -m -c backlight 2>/dev/null | cut -d, -f4)\";" +
            "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1);" +
            "[ -n \"$b\" ] && printf 'bat\\t%s %s\\n' \"$(cat \"$b/capacity\")\" \"$(cat \"$b/status\")\";" +
            "printf 'disk\\t%s\\n' \"$(df -h --output=avail / | tail -1 | tr -d ' ')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const a = {}
                for (const l of text.split("\n")) {
                    const i = l.indexOf("\t")
                    if (i > 0) a[l.substr(0, i)] = l.substr(i + 1).trim()
                }
                if (a.face !== p.info.face) p.stamp++
                p.info = a
            }
        }
    }
    Timer { interval: 5000; running: Pal.open; repeat: true; onTriggered: p.refresh() }

    // ---- derived text -------------------------------------------------------------------------
    readonly property string fullName: value("name", value("user", ""))
    readonly property string initial: fullName ? fullName.charAt(0).toUpperCase() : "?"
    readonly property string netText: {
        const n = value("net", "")
        if (!n) return "Not connected"
        const f = n.split(":")
        return (f[1] === "802-3-ethernet" ? "Ethernet · " : "") + f[0]
    }
    readonly property string btText: {
        if (value("bt", "") !== "yes") return "Off"
        const d = value("btdev", "")
        return d ? "On · " + d : "On · nothing connected"
    }
    readonly property string volText: {
        const m = /Volume:\s*([\d.]+)(\s*\[MUTED\])?/.exec(value("vol", ""))
        if (!m) return ""
        return m[2] ? "Muted" : Math.round(+m[1] * 100) + " %"
    }
    readonly property string batText: {
        const f = value("bat", "").split(" ")
        if (f.length < 2) return "No battery"
        const st = f.slice(1).join(" ")
        return f[0] + " %" + (st === "Charging" ? " · charging" : st === "Not charging" ? " · plugged in, at the charge limit"
                              : st === "Full" ? " · full" : "")
    }

    // ---- you ---------------------------------------------------------------------------------
    Group {
        Item {
            width: parent.width
            height: 96 * Pal.ui

            Item {
                id: avatar
                x: Pal.pad; anchors.verticalCenter: parent.verticalCenter
                width: 64 * Pal.ui; height: width

                Rectangle {   // initial, when there is no picture
                    anchors.fill: parent
                    radius: width / 2
                    color: Pal.primary
                    visible: pic.status !== Image.Ready
                    Text {
                        anchors.centerIn: parent
                        text: p.initial
                        color: Pal.primaryFg
                        font.family: Pal.font; font.pixelSize: 28 * Pal.ui; font.weight: Font.DemiBold
                    }
                }
                Image {
                    id: pic
                    anchors.fill: parent
                    visible: false
                    source: p.value("face", "") ? "file://" + p.info.face + "?" + p.stamp : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 192
                    asynchronous: true
                }
                Rectangle {
                    id: round
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {   // the picture, cut to a circle
                    anchors.fill: parent
                    visible: pic.status === Image.Ready
                    source: pic
                    maskEnabled: true
                    maskSource: round
                }
            }
            Column {
                anchors.left: avatar.right; anchors.leftMargin: 16 * Pal.ui
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * Pal.ui
                Text {
                    text: p.fullName
                    color: Pal.text
                    font.family: Pal.font; font.pixelSize: 18 * Pal.ui; font.weight: Font.DemiBold
                }
                Text {
                    text: p.value("user", "") + "@" + p.value("host", "")
                          + (p.value("model", "") ? " · " + p.info.model : "")
                    color: Pal.muted
                    font.family: Pal.font; font.pixelSize: Pal.fsSmall
                }
                Text {
                    text: p.value("up", "") ? "Up " + p.info.up : ""
                    color: Pal.muted
                    font.family: Pal.font; font.pixelSize: Pal.fsSmall
                }
            }
        }
    }

    // ---- quick status -------------------------------------------------------------------------
    Group {
        title: "At a glance"
        footer: "Click a row to open its section. A picture at ~/.face is used as your photo."

        component Status: SRow {
            property string target: ""
            property string value: ""
            clickable: true
            onClicked: Pal.navigate(target)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 360 * Pal.ui)
                elide: Text.ElideRight
                text: parent.parent.value
                color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fs
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""; color: Pal.muted
                font.family: Pal.icons; font.pixelSize: Pal.fsSmall
            }
        }

        Status { icon: ""; iconColor: "#0a84ff"; title: "Wi-Fi"; value: p.netText; target: "Network" }
        Status { icon: ""; iconColor: "#0a84ff"; title: "Bluetooth"; value: p.btText; target: "Bluetooth" }
        Status { icon: ""; iconColor: "#ff375f"; title: "Sound"; value: p.volText; target: "Sound" }
        Status { icon: ""; iconColor: "#0a84ff"; title: "Brightness"; value: p.value("bright", "").replace("%", " %"); target: "Display" }
        Status { icon: ""; iconColor: "#30d158"; title: "Battery"; value: p.batText; target: "Power" }
        Status { icon: ""; iconColor: "#8e8e93"; title: "Storage"; value: p.value("disk", "") ? p.info.disk + " free" : ""; target: "Storage" }
    }
}
