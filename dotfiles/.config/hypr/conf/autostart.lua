-- Execute your favorite apps at launch
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("dunst")
    -- Vietnamese input method
    hl.exec_cmd("fcitx5 -d")
end)
