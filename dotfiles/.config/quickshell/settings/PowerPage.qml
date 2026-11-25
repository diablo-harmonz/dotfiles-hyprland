// Battery: charge, time left and power draw (UPower), health and charge cycles (sysfs:
// UPower reports no health on this ThinkPad), power mode (power-profiles-daemon), the charge
// limit (bin/battery-mode, asks for the password), Caffeine, and what lid / idle do
// (HandleLidSwitch from /etc/systemd/logind.conf.d; hibernate delay only when it is used).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Page {
    id: p
    title: "Battery"

    readonly property var bat: UPower.displayDevice
    readonly property real level: !bat ? 0 : (bat.percentage > 1 ? bat.percentage / 100 : bat.percentage)
    readonly property bool charging: bat !== null && bat.state === UPowerDeviceState.Charging
    property string chargeMode: ""        // care / full (bin/battery-mode)
    property bool caffeine: false
    property string hibernateDelay: ""
    property string lidAction: ""         // HandleLidSwitch, e.g. suspend
    property int cycles: -1               // /sys/class/power_supply/BAT*/cycle_count
    property real energyFull: 0           // Wh now (energy_full)
    property real energyDesign: 0         // Wh when new (energy_full_design)
    readonly property int healthPct: energyDesign > 0 ? Math.min(100, Math.round(energyFull / energyDesign * 100)) : -1
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function duration(s) {
        if (!s || s <= 0) return ""
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }
    function stateText() {
        if (!bat) return "No battery"
        switch (bat.state) {
        case UPowerDeviceState.Charging:
            return "Charging" + (bat.timeToFull > 0 ? " · full in " + duration(bat.timeToFull) : "")
        case UPowerDeviceState.FullyCharged: return "Fully charged"
        case UPowerDeviceState.PendingCharge: return "Plugged in, not charging (charge limit)"
        case UPowerDeviceState.Discharging:
            return "On battery" + (bat.timeToEmpty > 0 ? " · " + duration(bat.timeToEmpty) + " left" : "")
        default: return UPower.onBattery ? "On battery" : "Plugged in"
        }
    }
    function refresh() { st.running = false; st.running = true }

    Process {
        id: st
        running: true
        command: ["sh", "-c",
            "printf 'C %s\\n' \"$(\"$HOME/.local/bin/battery-mode\" status | jq -r .class)\";" +
            "printf 'F %s\\n' \"$(\"$HOME/.local/bin/caffeine\" status | jq -r .class)\";" +
            "printf 'H %s\\n' \"$(grep -hs '^HibernateDelaySec=' /etc/systemd/sleep.conf.d/*.conf | tail -1 | cut -d= -f2)\";" +
            "printf 'L %s\\n' \"$(grep -hs '^HandleLidSwitch=' /etc/systemd/logind.conf.d/*.conf | tail -1 | cut -d= -f2)\";" +
            "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1);" +
            "[ -n \"$b\" ] && printf 'Y %s\\nE %s %s\\n' \"$(cat $b/cycle_count 2>/dev/null)\" \"$(cat $b/energy_full 2>/dev/null)\" \"$(cat $b/energy_full_design 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const k = line.charAt(0), v = line.substr(2).trim()
                    if (k === "C") p.chargeMode = v
                    else if (k === "F") p.caffeine = (v === "on")
                    else if (k === "H") p.hibernateDelay = v
                    else if (k === "L") p.lidAction = v
                    else if (k === "Y") p.cycles = /^\d+$/.test(v) ? parseInt(v) : -1
                    else if (k === "E") {
                        const e = v.split(" ")           // µWh
                        p.energyFull = (parseInt(e[0]) || 0) / 1e6
                        p.energyDesign = (parseInt(e[1]) || 0) / 1e6
                    }
                }
            }
        }
    }
    Timer { interval: 3000; running: Pal.open; repeat: true; onTriggered: p.refresh() }
    onReopened: refresh()

    // ---- battery ------------------------------------------------------------------------------
    Group {
        SRow {
            icon: p.charging ? "" : ""
            iconColor: p.level < 0.2 && !p.charging ? Pal.urgent : Pal.good
            title: Math.round(p.level * 100) + " %"
            subtitle: p.stateText()
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 160 * Pal.ui; height: 8 * Pal.ui; radius: height / 2
                color: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.15)
                Rectangle {
                    width: parent.width * p.level; height: parent.height; radius: parent.radius
                    color: p.level < 0.2 && !p.charging ? Pal.urgent : Pal.good
                }
            }
        }
        SRow {
            visible: p.healthPct >= 0
            icon: ""; title: "Battery health"
            subtitle: "Holds " + p.energyFull.toFixed(1) + " Wh, " + p.energyDesign.toFixed(1) + " Wh when new"
            Text {
                text: p.healthPct + " %"
                color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs
            }
        }
        SRow {
            visible: p.cycles >= 0
            icon: ""; title: "Charge cycles"
            subtitle: "One cycle = 100 % of the capacity used; partial charges add up"
            Text {
                text: p.cycles
                color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs
            }
        }
        SRow {
            visible: p.bat !== null && Math.abs(p.bat.changeRate) > 0.05
            icon: ""; title: p.charging ? "Charging power" : "Power draw"
            Text {
                text: p.bat ? Math.abs(p.bat.changeRate).toFixed(1) + " W" : ""
                color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs
            }
        }
    }

    // ---- modes --------------------------------------------------------------------------------
    Group {
        title: "Power"
        SRow {
            icon: ""; title: "Power mode"
            subtitle: "Also in the Control Center"
            Seg {
                options: PowerProfiles.hasPerformanceProfile
                    ? [{ key: "0", label: "Saver" }, { key: "1", label: "Balanced" }, { key: "2", label: "Performance" }]
                    : [{ key: "0", label: "Saver" }, { key: "1", label: "Balanced" }]
                current: PowerProfiles.profile === PowerProfile.PowerSaver ? "0"
                         : PowerProfiles.profile === PowerProfile.Performance ? "2" : "1"
                onPicked: k => PowerProfiles.profile = (k === "0" ? PowerProfile.PowerSaver
                                                        : k === "2" ? PowerProfile.Performance : PowerProfile.Balanced)
            }
        }
        SRow {
            icon: ""; title: "Charge limit"
            subtitle: p.chargeMode === "full" ? "Charges to 100 % (until the next boot)" : "Stops at 80 % to keep the battery healthy"
            Seg {
                options: [{ key: "care", label: "80 %" }, { key: "full", label: "100 %" }]
                current: p.chargeMode
                onPicked: k => { if (k !== p.chargeMode) p.run("\"" + p.bin + "battery-mode\" " + k) }
            }
        }
        SRow {
            icon: ""; title: "Caffeine"
            subtitle: "Keep the laptop awake: no idle lock or sleep, closing the lid does not sleep"
            Toggle {
                checked: p.caffeine
                onToggled: v => { p.caffeine = v; p.run("\"" + p.bin + "caffeine\" toggle") }
            }
        }
    }

    // ---- sleep --------------------------------------------------------------------------------
    Group {
        title: "Sleep"
        footer: "Changing these needs editing hypridle.conf and /etc/systemd (see docs/sleep.md)."
        SRow {
            icon: ""; title: "Closing the lid"
            subtitle: p.lidAction === "suspend-then-hibernate" && p.hibernateDelay
                      ? "Sleeps, then hibernates after " + p.hibernateDelay
                      : p.lidAction === "hibernate" ? "Hibernates"
                      : p.lidAction === "ignore" ? "Does nothing"
                      : "Sleeps"
        }
        SRow {
            icon: ""; title: "When idle"
            subtitle: "Dim at 5 min, lock at 10, screen off at 11, sleep at 30 (on battery)"
        }
        SRow {
            title: "Now"
            Btn { text: "Lock"; onClicked: p.run("loginctl lock-session") }
            Btn { text: "Sleep"; onClicked: p.run("systemctl suspend") }
            Btn { text: "Hibernate"; onClicked: p.run("systemctl hibernate") }
            Btn { text: "Power menu…"; onClicked: { p.run("\"" + p.bin + "power-menu\""); Pal.closeRequested() } }
        }
    }
}
