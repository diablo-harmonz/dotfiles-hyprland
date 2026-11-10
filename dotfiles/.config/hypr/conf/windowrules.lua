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
