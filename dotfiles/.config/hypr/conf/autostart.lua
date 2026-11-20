-- Execute your favorite apps at launch
hl.on("hyprland.start", function()
    -- Bar, one per screen sized to it (bin/waybar-launch); log: journalctl --user -t waybar
    hl.exec_cmd("~/.local/bin/waybar-launch")
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
    -- Media: playerctld tracks the most recently active player, so the media keys and
    -- the Waybar play button act on the one making sound (not the first one listed)
    hl.exec_cmd("playerctld daemon")
    -- Night light (hyprsunset.conf)
    hl.exec_cmd("hyprsunset")
    -- Notify on power mode changes (Fn+F8 switches it in firmware, no key event)
    hl.exec_cmd("~/.local/bin/powermode-notify")
    -- Mic-mute LED (F4) matches the mic's mute state (bin/osd); wait for PipeWire
    hl.exec_cmd("sleep 3; ~/.local/bin/osd mic sync")
    -- Vietnamese input method
    hl.exec_cmd("fcitx5 -d")
    -- Floating widgets on workspace 1: welcome terminal, ... (startup-layout.lua)
    require("conf.startup-layout").start()
end)

-- A screen plugged in or removed: rebuild the bars so each new screen gets one sized to it
-- (waybar-launch waits 2 s for the change to settle and drops the repeated events)
hl.on("monitor.added",   function() hl.exec_cmd("~/.local/bin/waybar-launch 2") end)
hl.on("monitor.removed", function() hl.exec_cmd("~/.local/bin/waybar-launch 2") end)
