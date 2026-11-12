-- Execute your favorite apps at launch
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    -- Wallpaper (awww) and its colors
    hl.exec_cmd("~/.local/bin/wallpaper restore")
    -- Notifications (swaync) and tray applets for Wi-Fi and Bluetooth
    hl.exec_cmd("swaync")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    -- Idle: dim, lock, screens off, suspend on battery (hypridle.conf)
    hl.exec_cmd("hypridle")
    -- Night light (hyprsunset.conf)
    hl.exec_cmd("hyprsunset")
    -- Notify on power mode changes (Fn+F8 switches it in firmware, no key event)
    hl.exec_cmd("~/.local/bin/powermode-notify")
    -- Vietnamese input method
    hl.exec_cmd("fcitx5 -d")
end)
