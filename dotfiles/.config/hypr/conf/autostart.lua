-- Execute your favorite apps at launch
hl.on("hyprland.start", function()
    -- Bar; its log goes to the journal (journalctl --user -t waybar)
    hl.exec_cmd("systemd-cat -t waybar waybar")
    -- Wallpaper (awww) and its colors
    hl.exec_cmd("~/.local/bin/wallpaper restore")
    -- Notifications (swaync)
    hl.exec_cmd("swaync")
    -- Password prompt for apps that need admin rights (polkit)
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    -- Clipboard history (SUPER+V): last 10 entries, each kept 5 minutes
    hl.exec_cmd("wl-paste --type text --watch ~/.local/bin/clipboard store text")
    hl.exec_cmd("wl-paste --type image --watch ~/.local/bin/clipboard store image")
    hl.exec_cmd("~/.local/bin/clipboard prune")
    -- Idle: dim, lock, screens off, suspend on battery (hypridle.conf)
    hl.exec_cmd("systemd-cat -t hypridle hypridle")   -- log: journalctl --user -t hypridle
    -- Night light (hyprsunset.conf)
    hl.exec_cmd("hyprsunset")
    -- Notify on power mode changes (Fn+F8 switches it in firmware, no key event)
    hl.exec_cmd("~/.local/bin/powermode-notify")
    -- Vietnamese input method
    hl.exec_cmd("fcitx5 -d")
    -- Floating widgets on workspace 1: welcome terminal, ... (startup-layout.lua)
    require("conf.startup-layout").start()
end)
