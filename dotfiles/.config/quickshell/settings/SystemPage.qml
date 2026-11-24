// About: this computer (model, CPU, GPU, memory, system, kernel, Hyprland,
// packages, uptime), pending updates (checkupdates + AUR, checked in the background) and
// shortcuts to bin/sysupdate, btop and bin/sysreport.
import QtQuick
import Quickshell
import Quickshell.Io

Page {
    id: p
    title: "About"

    property var about: ({})
    property int updates: -1          // official packages, -1 = checking
    property int aur: -1
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    property real checkedAt: Date.now()
    onReopened: {
        aboutProc.running = false; aboutProc.running = true
        if (Date.now() - checkedAt > 600000) { checkedAt = Date.now(); updProc.running = false; updProc.running = true }
    }

    Process {
        id: aboutProc
        running: true
        command: ["sh", "-c",
            "printf 'model\\t%s %s\\n' \"$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)\" \"$(cat /sys/class/dmi/id/product_version 2>/dev/null)\";" +
            "printf 'cpu\\t%s\\n' \"$(lscpu | sed -n 's/^Model name: *//p' | head -1)\";" +
            "printf 'gpu\\t%s\\n' \"$(lspci | grep -iE 'vga|3d|display' | head -1 | sed 's/.*: //; s/ (rev .*//')\";" +
            "printf 'mem\\t%s\\n' \"$(awk '/MemTotal/ {printf \"%.0f GB\", $2/1000/1000}' /proc/meminfo)\";" +
            "printf 'os\\t%s\\n' \"$(. /etc/os-release; echo \"$PRETTY_NAME\")\";" +
            "printf 'kernel\\t%s\\n' \"$(uname -r)\";" +
            "printf 'hypr\\t%s\\n' \"$(hyprctl version -j 2>/dev/null | jq -r .tag)\";" +
            "printf 'pkgs\\t%s\\n' \"$(pacman -Qq | wc -l)\";" +
            "printf 'host\\t%s\\n' \"$(cat /etc/hostname 2>/dev/null || uname -n)\";" +
            "printf 'up\\t%s\\n' \"$(uptime -p | sed 's/^up //')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const a = {}
                for (const l of text.split("\n")) { const f = l.split("\t"); if (f.length === 2) a[f[0]] = f[1] }
                p.about = a
            }
        }
    }
    Process {   // needs the network; a few seconds
        id: updProc
        running: true
        command: ["sh", "-c", "printf '%s %s\\n' \"$(checkupdates 2>/dev/null | wc -l)\" \"$(yay -Qua 2>/dev/null | wc -l)\""]
        stdout: StdioCollector {
            onStreamFinished: { const f = text.trim().split(" "); p.updates = +f[0]; p.aur = +f[1] }
        }
    }

    component Info: SRow {
        property string value: ""
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 420 * Pal.ui)
            elide: Text.ElideRight
            text: parent.parent.value
            color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fs
        }
    }

    Group {
        SRow {
            icon: ""; iconColor: Pal.primary
            title: p.about.model || "This computer"
            subtitle: (p.about.host || "") + (p.about.up ? " · up " + p.about.up : "")
        }
    }

    Group {
        title: "Details"
        Info { title: "Processor"; value: p.about.cpu || "" }
        Info { title: "Graphics"; value: p.about.gpu || "" }
        Info { title: "Memory"; value: p.about.mem || "" }
        Info { title: "System"; value: p.about.os || "" }
        Info { title: "Kernel"; value: p.about.kernel || "" }
        Info { title: "Hyprland"; value: p.about.hypr || "" }
        Info { title: "Packages"; value: p.about.pkgs ? p.about.pkgs + " (pacman)" : "" }
    }

    Group {
        title: "Software update"
        footer: "sysupdate shows Arch news, what will change and takes a snapshot before updating."
        SRow {
            icon: ""
            iconColor: p.updates > 0 || p.aur > 0 ? Pal.primary : Pal.muted
            title: p.updates < 0 ? "Checking for updates…"
                   : (p.updates + p.aur === 0 ? "Everything is up to date"
                      : p.updates + " update" + (p.updates === 1 ? "" : "s") + (p.aur > 0 ? " + " + p.aur + " from the AUR" : ""))
            Btn {
                text: "Update…"; accent: p.updates + p.aur > 0
                onClicked: { p.run("kitty --title 'System update' \"" + p.bin + "sysupdate\""); Pal.closeRequested() }
            }
        }
    }

    Group {
        title: "Tools"
        SRow {
            icon: ""; title: "Activity monitor"; subtitle: "btop"
            Btn { text: "Open"; onClicked: { p.run("kitty --title btop btop"); Pal.closeRequested() } }
        }
        SRow {
            icon: ""; title: "System report"; subtitle: "Full hardware and log report to ~/sysreport (asks for the password)"
            Btn { text: "Create…"; onClicked: { p.run("kitty --title 'System report' \"" + p.bin + "sysreport\""); Pal.closeRequested() } }
        }
    }
}
