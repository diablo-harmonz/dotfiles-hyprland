// Configs: open the config files of this setup in nvim (kitty), the dotfiles repo in yazi,
// and reload Hyprland / Waybar after editing (Hyprland is checked first).
import QtQuick
import Quickshell

Page {
    id: p
    title: "Configs"

    readonly property string home: Quickshell.env("HOME")
    readonly property string repo: home + "/Documents/personal/dotfiles-hyprland"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    function edit(file, name) {
        Quickshell.execDetached(["kitty", "--title", name, "--directory", file.replace(/\/[^\/]*$/, ""), "nvim", file])
        Pal.closeRequested()
    }

    readonly property var groups: [
        { title: "Hyprland", files: [
            { name: "Key bindings", path: "~/.config/hypr/conf/binds.lua" },
            { name: "Main config", path: "~/.config/hypr/hyprland.lua" },
            { name: "Window rules", path: "~/.config/hypr/conf/windowrules.lua" },
            { name: "Monitors", path: "~/.config/hypr/conf/monitor.lua" },
            { name: "Input (keyboard, touchpad)", path: "~/.config/hypr/conf/input.lua" },
            { name: "Autostart", path: "~/.config/hypr/conf/autostart.lua" },
            { name: "Idle, lock and sleep", path: "~/.config/hypr/hypridle.conf" },
            { name: "Lock screen", path: "~/.config/hypr/hyprlock.conf" },
            { name: "Night light", path: "~/.config/hypr/hyprsunset.conf" } ] },
        { title: "Bar, launcher, terminal", files: [
            { name: "Waybar modules", path: "~/.config/waybar/config" },
            { name: "Waybar style", path: "~/.config/waybar/style.css" },
            { name: "Launcher (rofi)", path: "~/.config/rofi/config.rasi" },
            { name: "Terminal (kitty)", path: "~/.config/kitty/kitty.conf" },
            { name: "Shell (zsh)", path: "~/.zshrc" } ] }
    ]

    Repeater {
        model: p.groups
        Group {
            required property var modelData
            title: modelData.title
            Repeater {
                model: modelData.files
                SRow {
                    required property var modelData
                    clickable: true
                    icon: ""
                    title: modelData.name
                    subtitle: modelData.path
                    onClicked: p.edit(modelData.path.replace(/^~/, p.home), modelData.name)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""; color: Pal.muted
                        font.family: Pal.icons; font.pixelSize: Pal.fsSmall
                    }
                }
            }
        }
    }

    Group {
        title: "After editing"
        footer: "Hyprland reloads by itself when its files are saved; use Reload only if it did not."
        SRow {
            icon: ""; title: "Reload Hyprland"
            subtitle: "Checks the config first (Hyprland --verify-config); errors are shown instead"
            Btn {
                text: "Reload"
                onClicked: p.run("out=$(cd / && timeout 60 Hyprland --verify-config --config \"$HOME/.config/hypr/hyprland.lua\" 2>&1 "
                                 + "| sed -n '/Config parsing result/,$p' | sed '/Config parsing result/d; /^$/d'); "
                                 + "if [ \"$out\" = 'config ok' ]; then hyprctl reload >/dev/null && notify-send -a settings Hyprland 'Config reloaded'; "
                                 + "else notify-send -a settings 'Hyprland: not reloaded' \"$(printf '%s' \"$out\" | head -5)\"; fi")
            }
        }
        SRow {
            icon: ""; title: "Restart Waybar"
            Btn { text: "Restart"; onClicked: p.run("\"" + p.home + "/.local/bin/waybar-launch\"") }
        }
        SRow {
            icon: ""; title: "Dotfiles repo"
            subtitle: p.repo.replace(p.home, "~")
            Btn { text: "Open in yazi"; onClicked: { p.run("kitty --title yazi --directory '" + p.repo + "' yazi"); Pal.closeRequested() } }
        }
    }
}
