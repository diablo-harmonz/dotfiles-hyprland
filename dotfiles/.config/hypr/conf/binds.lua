-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- SUPER key
local mainMod = "SUPER"

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- Actions
hl.bind(mainMod .. " + RETURN",         exec("wezterm"))                                                   -- Open WezTerm
hl.bind(mainMod .. " + Q",              hl.dsp.window.close())                                             -- Close current window
hl.bind(mainMod .. " + M",              hl.dsp.exit())                                                     -- Exit Hyprland
hl.bind(mainMod .. " + E",              exec("~/.config/ml4w/settings/filemanager.sh"))                    -- Opens the filemanager
hl.bind(mainMod .. " + T",              hl.dsp.window.float({ action = "toggle" }))                        -- Toggle tiling/floating
hl.bind(mainMod .. " + F",              hl.dsp.window.fullscreen())                                        -- Fullscreen
hl.bind(mainMod .. " + SPACE",          exec("rofi -show drun"))                                           -- Open rofi (app launcher)
hl.bind(mainMod .. " + P",              hl.dsp.window.pseudo())                                            -- dwindle
hl.bind(mainMod .. " + J",              hl.dsp.layout("togglesplit"))                                      -- dwindle
hl.bind(mainMod .. " + B",              exec("~/.config/ml4w/settings/browser.sh"))                        -- Opens the browser
hl.bind(mainMod .. " + SHIFT + B",      exec("~/.config/ml4w/scripts/reload-waybar.sh"))                   -- Reload Waybar
hl.bind(mainMod .. " + CTRL + R",       exec("hyprctl reload"))                                            -- Emergency: reload config, restores all screens
hl.bind(mainMod .. " + SHIFT + W",      exec("~/.config/ml4w/scripts/reload-hyprpaper.sh"))                -- Reload hyprpaper
hl.bind(mainMod .. " + L",              exec("loginctl lock-session"))                                     -- Lock the screen (hypridle runs hyprlock)
hl.bind(mainMod .. " + SHIFT + C",      exec("~/.local/bin/caffeine toggle"))                              -- Keep awake on/off (no idle lock or suspend)

-- Lid: only acts while caffeine is on (otherwise logind suspends and hypridle locks first)
hl.bind("switch:on:Lid Switch",  exec("~/.local/bin/caffeine lid-close"), { locked = true })
hl.bind("switch:off:Lid Switch", exec("~/.local/bin/caffeine lid-open"),  { locked = true })

-- Hardware keys
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl set 10%+"))
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 10%-"))
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86WLAN",              exec("nmcli radio wifi toggle"))
hl.bind("XF86Refresh",           exec("wtype -k F5"))
hl.bind("XF86SelectiveScreenshot", exec("~/.local/bin/screenshot area"))  -- Fn+F10: select a region -> file + clipboard
hl.bind("XF86Favorites",         exec("rofi -show drun"))                    -- Fn+F12 (star): app launcher
hl.bind("XF86Display",           exec("~/.local/bin/display-toggle"))        -- Fn+F7: cycle external monitor mirror -> extended -> off
hl.bind("code:248",              hl.dsp.window.fullscreen())                   -- Fn+F11 (no keysym, keycode 248): fullscreen the active window
hl.bind("XF86AudioPlay",         exec("playerctl play-pause"))
hl.bind("XF86AudioNext",         exec("playerctl next"))
hl.bind("XF86AudioPrev",         exec("playerctl previous"))
hl.bind("XF86AudioStop",         exec("playerctl stop"))

-- Screenshots (~/Pictures/Screenshots) and screen recording (~/Videos/Recordings)
hl.bind("Print",                    exec("~/.local/bin/screenshot full"))   -- Fn+F9 (PrtSc): whole screen -> file + clipboard
hl.bind("SHIFT + Print",            exec("~/.local/bin/screenshot area"))   -- Select a region -> file + clipboard
hl.bind(mainMod .. " + Print",      exec("~/.local/bin/screenshot edit"))   -- Select a region -> annotate in satty
hl.bind(mainMod .. " + SHIFT + R",  exec("~/.local/bin/screenrec area"))    -- Start/stop recording a region
hl.bind(mainMod .. " + ALT + R",    exec("~/.local/bin/screenrec full"))    -- Start/stop recording the whole screen

-- Move focus with mainMod + arrow keys
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
end

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
