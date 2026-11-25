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
hl.layer_rule({ match = { namespace = "control-center" }, blur = true, ignore_alpha = 0.3 })
-- Settings panel (quickshell/settings): only the panel is blurred, not its 0.30 dark backdrop
hl.layer_rule({ match = { namespace = "settings" }, blur = true, ignore_alpha = 0.4 })   -- bin/control-center (the full-screen backdrop is transparent)

-- Translucent apps: add a line to make an app see-through (blur shows the wallpaper behind).
-- class   = the window class: focus the app, then run `hyprctl activewindow -j | jq -r .class`
--           in a terminal within a few seconds, or see them all with `hyprctl clients`
--           (navi, Ctrl+G: "window class")
-- active  = opacity while focused, inactive = while another window is focused (1 = solid)
-- This fades the whole window, text included. Terminals like kitty fade only their
-- background with their own setting (background_opacity), so they are not listed here.
-- Reload with SUPER+CTRL+R; the change also applies to windows that are already open.
local translucent = {
    { class = "org.telegram.desktop", active = 0.85, inactive = 0.75 },
    { class = "firefox",              active = 0.87, inactive = 0.77 },
    { class = "discord",              active = 0.85, inactive = 0.75 },
    { class = "org.gnome.Nautilus",   active = 0.90, inactive = 0.80 },
}
for _, app in ipairs(translucent) do
    hl.window_rule({
        name    = "translucent-" .. app.class,
        match   = { class = "^(" .. app.class:gsub("%.", "\\.") .. ")$" },
        opacity = string.format("%.2f %.2f", app.active, app.inactive),
    })
end

-- cava audio visualizer (bin/cava-toggle, SUPER+A): tall floating panel
hl.window_rule({
    name  = "cava-visualizer",
    match = { class = "^(cava)$" },

    float  = true,
    size   = "380 830",
    center = true,
})

-- Phone link (bin/phone-link, Fn+F11): menu and QR code in a floating terminal
hl.window_rule({
    name  = "phone-link",
    match = { class = "^(phone-link)$" },

    float  = true,
    size   = "640 720",
    center = true,
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
