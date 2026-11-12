-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Yakuake: floating drop-down terminal at the top, visible on every workspace
hl.window_rule({
    name  = "yakuake-dropdown",
    match = { class = "^(org.kde.yakuake)$" },

    float = true,
    pin   = true,
    size  = "(monitor_w*1) (monitor_h*0.5)",
    move  = "0 0",
})

-- Blur behind the launcher and the bar (their backgrounds are translucent)
hl.layer_rule({ match = { namespace = "rofi" },   blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "swaync-control-center" },      blur = true, ignore_alpha = 0.1 })
