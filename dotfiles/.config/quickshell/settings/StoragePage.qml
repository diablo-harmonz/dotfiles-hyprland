// Storage: the system disk (btrfs, shared by / and /home), the biggest places on it, swap
// (zram first, the hibernate swapfile second), and shortcuts to Timeshift and to clean the
// pacman cache (both ask for the password).
import QtQuick
import Quickshell
import Quickshell.Io

Page {
    id: p
    title: "Storage"

    property real size: 0
    property real used: 0
    property real avail: 0
    property var places: []       // { name, path, bytes }
    property var swaps: []        // { name, size, used, prio } in bytes
    property bool measuring: true

    function human(b) {
        const u = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (b >= 1000 && i < u.length - 1) { b /= 1000; i++ }
        return (i >= 3 ? b.toFixed(1) : b.toFixed(0)) + " " + u[i]
    }
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    onReopened: { dfProc.running = false; dfProc.running = true; duProc.running = false; duProc.running = true }

    Process {
        id: dfProc
        running: true
        command: ["sh", "-c", "df -B1 --output=size,used,avail / | tail -1; cat /proc/swaps"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const f = lines[0].trim().split(/\s+/)
                p.size = +f[0]; p.used = +f[1]; p.avail = +f[2]
                const s = []
                for (const l of lines.slice(2)) {
                    const g = l.trim().split(/\s+/)
                    if (g.length >= 5) s.push({ name: g[0], size: +g[2] * 1024, used: +g[3] * 1024, prio: +g[4] })
                }
                p.swaps = s
            }
        }
    }
    // du in the background: a big home folder must not hold up the page
    Process {
        id: duProc
        running: true
        command: ["sh", "-c",
            "for d in \"$HOME\" \"$HOME/.cache\" \"$HOME/Downloads\" \"$HOME/Videos\" \"$HOME/Pictures\" /var/cache/pacman/pkg /var/log; do " +
            "  [ -d \"$d\" ] && printf '%s\\t%s\\n' \"$(du -sxb \"$d\" 2>/dev/null | cut -f1)\" \"$d\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const home = Quickshell.env("HOME")
                const names = {}
                names[home] = "Home folder (all)"; names[home + "/.cache"] = "App caches"
                names[home + "/Downloads"] = "Downloads"; names[home + "/Videos"] = "Videos"
                names[home + "/Pictures"] = "Pictures"; names["/var/cache/pacman/pkg"] = "Package cache"
                names["/var/log"] = "System logs"
                p.places = text.trim().split("\n").map(l => l.split("\t"))
                    .filter(f => f.length === 2 && f[0] !== "")
                    .map(f => ({ name: names[f[1]] || f[1], path: f[1], bytes: +f[0] }))
                p.measuring = false
            }
        }
    }

    Group {
        title: "System disk"
        SRow {
            icon: "";             title: p.human(p.avail) + " free of " + p.human(p.size)
            subtitle: p.human(p.used) + " used · btrfs, shared by the system and the home folder"
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 200 * Pal.ui; height: 8 * Pal.ui; radius: height / 2
                color: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.15)
                Rectangle {
                    width: p.size > 0 ? parent.width * p.used / p.size : 0
                    height: parent.height; radius: parent.radius
                    color: p.size > 0 && p.used / p.size > 0.9 ? Pal.urgent : Pal.primary
                }
            }
        }
    }

    Group {
        title: "What takes space"
        SRow { visible: p.measuring; title: "Measuring…" }
        Repeater {
            model: p.places
            SRow {
                required property var modelData
                icon: modelData.path.startsWith("/var") ? "" : ""
                title: modelData.name
                subtitle: modelData.path
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: p.human(modelData.bytes)
                    color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs
                }
            }
        }
    }

    Group {
        title: "Swap"
        footer: "zram (compressed RAM) is used first; the swapfile is mostly for hibernating."
        Repeater {
            model: p.swaps
            SRow {
                required property var modelData
                icon: ""
                title: modelData.name.indexOf("zram") >= 0 ? "zram (in RAM)" : "Swapfile"
                subtitle: modelData.name + " · priority " + modelData.prio
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: p.human(modelData.used) + " / " + p.human(modelData.size)
                    color: Pal.text; font.family: Pal.font; font.pixelSize: Pal.fs
                }
            }
        }
    }

    Group {
        title: "Maintenance"
        SRow {
            icon: ""; title: "Timeshift snapshots"
            subtitle: "Daily and before every update; restore from here or from the GRUB menu"
            Btn { text: "Open Timeshift"; onClicked: { p.run("timeshift-launcher"); Pal.closeRequested() } }
        }
        SRow {
            icon: ""; title: "Package cache"
            subtitle: "Keep the last 2 versions of each package (paccache -rk2)"
            Btn {
                text: "Clean…"
                onClicked: { p.run("kitty --title 'Clean package cache' sh -c 'sudo paccache -rk2; sudo paccache -ruk0; echo; read -r -p \"Done. Enter to close \" _'"); Pal.closeRequested() }
            }
        }
    }
}
