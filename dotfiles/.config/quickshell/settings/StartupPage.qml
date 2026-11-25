// Startup apps: apps started at login (bin/autostart, XDG entries in ~/.config/autostart).
// A switch turns one on or off for the next login (the entry stays), Remove deletes it,
// Add picks an installed app in rofi (the panel closes and reopens here). Desktop services
// (Waybar, notifications, polkit, input method, idle) are in hypr/conf/autostart.lua.
import QtQuick
import Quickshell
import Quickshell.Io

Page {
    id: p
    title: "Startup apps"

    readonly property string tool: Quickshell.env("HOME") + "/.local/bin/autostart"
    property var apps: []          // { id, on, name, cmd }
    property bool loaded: false

    function refresh() { ls.running = false; ls.running = true }
    function act(args) {
        if (doer.running) return
        doer.command = [p.tool].concat(args)
        doer.running = true
    }

    Process {
        id: ls
        running: true
        command: [p.tool, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of text.split("\n")) {
                    const f = line.split("\t")
                    if (f.length < 4) continue
                    out.push({ id: f[0], on: f[1] === "enabled", name: f[2], cmd: f[3] })
                }
                out.sort((a, b) => a.name.localeCompare(b.name))
                p.apps = out
                p.loaded = true
            }
        }
    }
    Process {
        id: doer
        onExited: p.refresh()
    }
    onReopened: refresh()

    Group {
        title: "Start at login"
        footer: "Changes apply at the next login. Apps that offer \"start at login\" in their own "
                + "settings show up here too."
        SRow {
            visible: p.loaded && p.apps.length === 0
            icon: "\uf05a"; title: "No startup apps"
            subtitle: "Add one below"
        }
        Repeater {
            model: p.apps
            SRow {
                required property var modelData
                icon: "\uf135"
                title: modelData.name
                subtitle: modelData.cmd
                Btn {
                    text: "Remove"; danger: true
                    onClicked: p.act(["remove", modelData.id])
                }
                Toggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: modelData.on
                    busy: doer.running
                    onToggled: v => p.act([v ? "enable" : "disable", modelData.id])
                }
            }
        }
    }

    Group {
        SRow {
            icon: "\uf067"; title: "Add an app"
            subtitle: "Pick from the installed apps"
            Btn {
                text: "Add…"; accent: true
                onClicked: { Quickshell.execDetached([p.tool, "pick"]); Pal.closeRequested() }
            }
        }
    }
}
