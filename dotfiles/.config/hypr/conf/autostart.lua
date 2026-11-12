-- Execute your favorite apps at launch
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("dunst")
    -- Idle: dim, lock, screens off, suspend on battery (hypridle.conf)
    hl.exec_cmd("hypridle")
    -- Night light (hyprsunset.conf)
    hl.exec_cmd("hyprsunset")
    -- Notify on power mode changes (Fn+F8 switches it in firmware, no key event)
    hl.exec_cmd("~/.local/bin/powermode-notify")
    -- Vietnamese input method
    hl.exec_cmd("fcitx5 -d")
end)
