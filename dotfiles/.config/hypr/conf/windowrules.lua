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
hl.layer_rule({ match = { namespace = "logout_dialog" },              blur = true })   -- wlogout (bin/power-menu)
hl.layer_rule({ match = { namespace = "control-center" }, blur = true, ignore_alpha = 0.3 })   -- bin/control-center (the full-screen backdrop is transparent)

-- cava audio visualizer (bin/cava-toggle, SUPER+A): tall floating panel
hl.window_rule({
    name  = "cava-visualizer",
    match = { class = "^(cava)$" },

    float  = true,
    size   = "380 830",
    center = true,
})

-- Terminal popups from Waybar (bin/tui-popup): wiremix (volume) and bluetui (Bluetooth),
-- floating under the right end of the bar. The bar is centred and ~77 % wide, so its
-- right edge is at ~88.5 % of the screen width on every monitor.
hl.window_rule({
    name  = "tui-popup",
    match = { class = "^(tui-.*)$" },

    float = true,
    size  = "900 560",
    move  = "(monitor_w*0.885-900) 52",
})

-- yt-x videos (mpv started with --wayland-app-id=mpv-pip in yt-x/config): small floating
-- window in the bottom-right corner, pinned to every workspace (picture-in-picture).
-- SUPER+F for full screen, SUPER+O to unpin.
hl.window_rule({
    name  = "yt-x-pip",
    match = { class = "^(mpv-pip)$" },

    float = true,
    pin   = true,
    size  = "(monitor_w*0.3) (monitor_h*0.3)",
    move  = "(monitor_w*0.69) (monitor_h*0.68)",
    keep_aspect_ratio = true,
})
