// Bluetooth: on/off, paired devices (connect / disconnect, battery, forget) and nearby
// devices (scanning while this page is open; Pair pairs, trusts and connects).
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Page {
    id: p
    title: "Bluetooth"

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled
    readonly property var all: adapter ? adapter.devices.values : []
    readonly property var mine: all.filter(d => d.paired || d.bonded)
                                   .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // Nearby: unpaired devices that have a real name (not just their address)
    readonly property var nearby: all.filter(d => !d.paired && !d.bonded && d.deviceName !== ""
                                             && d.name.replace(/-/g, ":") !== d.address)

    function glyph(d) {
        // BlueZ's icon name when Quickshell has one, else a guess from the device name
        const n = (d.name || "").toLowerCase()
        const i = d.icon || (/mouse|mx master|mx anywhere|trackball/.test(n) ? "input-mouse"
                             : /keyboard|keys|mx mechanical/.test(n) ? "input-keyboard"
                             : /bud|pod|headphone|headset|major|wh-|wf-/.test(n) ? "audio-headset" : "")
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0 || i.indexOf("audio") >= 0) return ""
        if (i.indexOf("mouse") >= 0) return "\u{F037D}"
        if (i.indexOf("keyboard") >= 0) return ""
        if (i.indexOf("phone") >= 0) return ""
        if (i.indexOf("computer") >= 0 || i.indexOf("video") >= 0) return ""
        if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0) return ""
        return ""
    }
    function status(d) {
        if (d.pairing) return "Pairing…"
        switch (d.state) {
        case BluetoothDeviceState.Connecting: return "Connecting…"
        case BluetoothDeviceState.Disconnecting: return "Disconnecting…"
        case BluetoothDeviceState.Connected:
            return "Connected" + (d.batteryAvailable ? " · battery " + Math.round(d.battery * 100) + " %" : "")
        default: return "Not connected"
        }
    }
    function pairAndConnect(d) {
        d.trusted = true
        d.pair()
    }

    // Look for devices only while the panel is open, through bluetoothctl in its own process
    // (setting adapter.discovering is a blocking D-Bus call); it stops when the process ends
    readonly property bool scanning: Pal.open && on
    property bool discovering: false
    Process {
        id: scanProc
        running: p.scanning
        command: ["bluetoothctl", "--timeout", "120", "scan", "on"]
        onRunningChanged: p.discovering = running
    }

    // A device that finished pairing from here connects right away
    Repeater {
        model: p.nearby
        Item {
            required property var modelData
            readonly property bool done: modelData.paired
            onDoneChanged: if (done) modelData.connect()
        }
    }

    Group {
        SRow {
            icon: ""; iconColor: "#0a84ff"
            title: "Bluetooth"
            subtitle: !p.adapter ? "No Bluetooth adapter"
                      : p.on ? "On · " + (p.discovering ? "looking for devices" : p.adapter.name) : "Off"
            Toggle {
                checked: p.on
                busy: p.adapter !== null && (p.adapter.state === BluetoothAdapterState.Enabling
                                             || p.adapter.state === BluetoothAdapterState.Disabling)
                onToggled: v => { if (p.adapter) p.adapter.enabled = v }
            }
        }
    }

    Group {
        title: "My devices"
        visible: p.on
        SRow {
            visible: p.mine.length === 0
            title: "No paired devices"
        }
        Repeater {
            model: p.mine
            SRow {
                required property var modelData
                icon: p.glyph(modelData)
                iconColor: modelData.connected ? Pal.primary : Pal.muted
                title: modelData.name
                subtitle: p.status(modelData)
                Btn {
                    text: modelData.connected ? "Disconnect" : "Connect"
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
                Btn { text: "Forget"; danger: true; onClicked: modelData.forget() }
            }
        }
    }

    Group {
        title: "Nearby devices"
        visible: p.on
        footer: "Put the device in pairing mode. Pair also trusts it, so it reconnects by itself."
        SRow {
            visible: p.nearby.length === 0
            title: p.discovering ? "Looking for devices…" : "Nothing found"
        }
        Repeater {
            model: p.nearby
            SRow {
                required property var modelData
                icon: p.glyph(modelData)
                title: modelData.name
                subtitle: modelData.pairing ? "Pairing…" : ""
                Btn {
                    text: modelData.pairing ? "Cancel" : "Pair"
                    accent: !modelData.pairing
                    onClicked: modelData.pairing ? modelData.cancelPair() : p.pairAndConnect(modelData)
                }
            }
        }
    }
}
