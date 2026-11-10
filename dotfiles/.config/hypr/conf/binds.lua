-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- SUPER key
local mainMod = "SUPER"

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- Actions
hl.bind(mainMod .. " + RETURN",         exec("wezterm"))                                                   -- Open WezTerm
hl.bind("CTRL + SHIFT + down",          exec("qdbus6 org.kde.yakuake /yakuake/window toggleWindowState")) -- Toggle Yakuake drop-down
hl.bind(mainMod .. " + Q",              hl.dsp.window.close())                                             -- Close current window
hl.bind(mainMod .. " + M",              hl.dsp.exit())                                                     -- Exit Hyprland
hl.bind(mainMod .. " + E",              exec("~/.config/ml4w/settings/filemanager.sh"))                    -- Opens the filemanager
hl.bind(mainMod .. " + T",              hl.dsp.window.float({ action = "toggle" }))                        -- Toggle tiling/floating
hl.bind(mainMod .. " + F",              hl.dsp.window.fullscreen())                                        -- Fullscreen
hl.bind(mainMod .. " + CTRL + RETURN",  exec("rofi -show drun"))                                           -- Open rofi
hl.bind(mainMod .. " + P",              hl.dsp.window.pseudo())                                            -- dwindle
hl.bind(mainMod .. " + J",              hl.dsp.layout("togglesplit"))                                      -- dwindle
hl.bind(mainMod .. " + B",              exec("~/.config/ml4w/settings/browser.sh"))                        -- Opens the browser
hl.bind(mainMod .. " + SHIFT + B",      exec("~/.config/ml4w/scripts/reload-waybar.sh"))                   -- Reload Waybar
hl.bind(mainMod .. " + SHIFT + W",      exec("~/.config/ml4w/scripts/reload-hyprpaper.sh"))                -- Reload hyprpaper

-- Hardware keys
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl set 10%+"))
hl.bind("XF86MonBrightnessDown", exec("brightnessctl set 10%-"))
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("XF86WLAN",              exec("nmcli radio wifi toggle"))
hl.bind("XF86Refresh",           exec("xdotool key F5"))

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
