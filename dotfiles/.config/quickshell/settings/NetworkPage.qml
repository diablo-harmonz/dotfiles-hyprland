// Wi-Fi: on/off, the current network (IP, live download / upload speed), Ethernet, and the
// networks around (scanning while this page is open). A secured network that is not saved
// yet asks for its password in the row.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Page {
    id: p
    title: "Wi-Fi"

    readonly property var devices: Networking.devices.values
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var current: wifi ? (wifi.networks.values.find(n => n.connected) ?? null) : null
    readonly property var others: {
        if (!wifi) return []
        const seen = {}
        return wifi.networks.values
            .filter(n => n.name !== "" && !n.connected)
            .sort((a, b) => (b.known - a.known) || (b.signalStrength - a.signalStrength))
            .filter(n => { if (seen[n.name]) return false; seen[n.name] = true; return true })
    }
    property string askFor: ""        // network name whose password row is open
    property string ip: ""
    property real rx: 0               // bytes per second
    property real tx: 0

    function secured(n) { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
    function speed(b) {
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
        if (b >= 1024) return (b / 1024).toFixed(0) + " KB/s"
        return b.toFixed(0) + " B/s"
    }
    function strength(n) { return n.signalStrength >= 0.66 ? 1 : n.signalStrength >= 0.33 ? 0.65 : 0.35 }
    function join(n) {
        if (n.known || !secured(n)) n.connect()
        else askFor = (askFor === n.name ? "" : n.name)
    }

    // Scan while the panel is open with Quickshell's own scanner. It has to be on: Quickshell
    // only lists the networks it scanned itself, so the earlier `nmcli device wifi rescan`
    // left the list at the current network alone ("Looking for networks…" when not connected,
    // 2026-11-26: nmcli saw 31 networks, the page 1). Switched on a moment after opening, so
    // the D-Bus call does not hold up the open animation (it took 0 ms in a test, once 1.6 s).
    Timer {
        id: scanOn
        interval: 400
        running: Pal.open && Networking.wifiEnabled && p.wifi !== null
        onTriggered: p.wifi.scannerEnabled = true
    }

    // ---- live speed and IP of the active interface ------------------------------------------
    readonly property string iface: current && wifi ? wifi.name : (wired && wired.connected ? wired.name : "")
    property var last: null
    FileView { id: netdev; path: "/proc/net/dev" }
    Timer {
        interval: 1000; running: Pal.open; repeat: true; triggeredOnStart: true
        onTriggered: {
            netdev.reload()
            const line = netdev.text().split("\n").find(l => l.trim().startsWith(p.iface + ":"))
            if (!p.iface || !line) { p.rx = p.tx = 0; p.last = null; return }
            const f = line.split(":")[1].trim().split(/\s+/)
            const now = { rx: +f[0], tx: +f[8], t: Date.now() }
            if (p.last) {
                const dt = Math.max(0.2, (now.t - p.last.t) / 1000)
                p.rx = Math.max(0, (now.rx - p.last.rx) / dt)
                p.tx = Math.max(0, (now.tx - p.last.tx) / dt)
            }
            p.last = now
        }
    }
    onReopened: { last = null; ipProc.running = false; if (iface) ipProc.running = true }
    onIfaceChanged: { last = null; ipProc.running = false; if (iface) ipProc.running = true }
    Process {
        id: ipProc
        command: ["sh", "-c", "ip -4 -o addr show dev \"$1\" | awk '{print $4}' | cut -d/ -f1 | head -1", "sh", p.iface]
        stdout: StdioCollector { onStreamFinished: p.ip = text.trim() }
    }

    // ---- page ---------------------------------------------------------------------------------
    Group {
        SRow {
            icon: "";             title: "Wi-Fi"
            subtitle: !p.wifi ? "No Wi-Fi adapter"
                      : !Networking.wifiHardwareEnabled ? "Turned off by the hardware switch"
                      : Networking.wifiEnabled ? (p.current ? "Connected to " + p.current.name : "Not connected") : "Off"
            Toggle {
                checked: Networking.wifiEnabled
                onToggled: v => Networking.wifiEnabled = v
            }
        }
    }

    Group {
        title: "Current network"
        visible: p.current !== null
        SRow {
            icon: ""; iconColor: Pal.primary
            title: p.current ? p.current.name : ""
            subtitle: p.current ? (p.current.stateChanging ? "Working…" : "Connected" + (p.ip ? " · " + p.ip : "")) : ""
            Btn { text: "Disconnect"; onClicked: p.current.disconnect() }
            Btn { text: "Forget"; danger: true; onClicked: p.current.forget() }
        }
        SRow {
            icon: ""; title: "Download"
            Text { text: p.speed(p.rx); color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs; font.features: { "tnum": 1 } }
        }
        SRow {
            icon: ""; title: "Upload"
            Text { text: p.speed(p.tx); color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs; font.features: { "tnum": 1 } }
        }
    }

    Group {
        title: "Ethernet"
        visible: p.wired !== null
        SRow {
            icon: "󰈀"
            title: p.wired ? p.wired.name : ""
            subtitle: !p.wired ? "" : p.wired.connected ? "Connected" + (p.wifi && p.current ? "" : (p.ip ? " · " + p.ip : ""))
                      : p.wired.hasLink ? "Cable plugged in, not connected" : "No cable"
            Text {
                text: p.wired && p.wired.connected && p.wired.linkSpeed > 0 ? p.wired.linkSpeed + " Mb/s" : ""
                color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
            }
        }
    }

    Group {
        title: "Other networks"
        visible: Networking.wifiEnabled && p.wifi !== null
        footer: "Saved networks first. A lock means a password is needed; saved ones connect without asking."

        SRow {
            visible: p.others.length === 0
            title: "Looking for networks…"
        }
        Repeater {
            model: p.others
            Column {
                id: net
                required property var modelData
                width: parent.width

                SRow {
                    clickable: true
                    icon: ""
                    iconColor: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, p.strength(net.modelData))
                    title: net.modelData.name
                    subtitle: net.modelData.stateChanging ? "Connecting…" : (net.modelData.known ? "Saved" : "")
                    onClicked: p.join(net.modelData)
                    Text {
                        visible: p.secured(net.modelData)
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""; color: Pal.muted
                        font.family: Pal.icons; font.pixelSize: Pal.fsSmall
                    }
                    Btn {
                        visible: net.modelData.known
                        text: "Forget"; danger: true
                        onClicked: net.modelData.forget()
                    }
                    Btn { text: "Connect"; onClicked: p.join(net.modelData) }
                }
                // Password row for a new secured network
                Item {
                    visible: p.askFor === net.modelData.name
                    width: parent.width
                    height: visible ? 46 * Pal.ui : 0
                    Rectangle {
                        id: field
                        x: Pal.pad + 30 * Pal.ui
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - join.width - 2 * Pal.pad - 8 * Pal.ui
                        height: 28 * Pal.ui
                        radius: Pal.radiusSm
                        color: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.08)
                        border.color: psk.activeFocus ? Pal.primary : Pal.line
                        TextInput {
                            id: psk
                            anchors.fill: parent
                            anchors.leftMargin: 10 * Pal.ui; anchors.rightMargin: 10 * Pal.ui
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Pal.text
                            selectionColor: Pal.primary
                            font.family: Pal.font; font.pixelSize: Pal.fs
                            clip: true
                            onVisibleChanged: if (visible) { text = ""; forceActiveFocus() }
                            Keys.onReturnPressed: join.clicked()
                            Keys.onEscapePressed: p.askFor = ""
                            activeFocusOnTab: true
                            Keys.onUpPressed: Pal.focusStep(psk, false)
                            Keys.onDownPressed: Pal.focusStep(psk, true)
                            Text {
                                visible: psk.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Password"
                                color: Pal.muted
                                font.family: Pal.font; font.pixelSize: Pal.fs
                            }
                        }
                    }
                    Btn {
                        id: join
                        anchors.right: parent.right; anchors.rightMargin: Pal.pad
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Join"; accent: true
                        enabled: psk.text.length >= 8
                        onClicked: if (enabled) { net.modelData.connectWithPsk(psk.text); p.askFor = "" }
                    }
                }
            }
        }
    }
}
