-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- SUPER key
local mainMod = "SUPER"

local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

-- Actions
hl.bind(mainMod .. " + RETURN",         exec("kitty"))                                                     -- Open kitty
hl.bind(mainMod .. " + Q",              hl.dsp.window.close())                                             -- Close current window
hl.bind(mainMod .. " + M",              hl.dsp.exit())                                                     -- Exit Hyprland
hl.bind(mainMod .. " + E",              exec("~/.config/ml4w/settings/filemanager.sh"))                    -- Opens the filemanager
hl.bind(mainMod .. " + SHIFT + E",      exec("kitty yazi"))                                                -- Yazi file manager in kitty
hl.bind(mainMod .. " + T",              hl.dsp.window.float({ action = "toggle" }))                        -- Toggle tiling/floating
hl.bind(mainMod .. " + O",              hl.dsp.window.pin())                                               -- Pin floating window to every workspace (PiP)
hl.bind(mainMod .. " + F",              hl.dsp.window.fullscreen())                                        -- Fullscreen
hl.bind(mainMod .. " + SPACE",          exec("~/.local/bin/launcher"))                                     -- Launcher: apps + web search (rofi)
hl.bind(mainMod .. " + P",              hl.dsp.window.pseudo())                                            -- dwindle
hl.bind(mainMod .. " + J",              hl.dsp.layout("togglesplit"))                                      -- dwindle
hl.bind(mainMod .. " + B",              exec("~/.config/ml4w/settings/browser.sh"))                        -- Opens the browser
hl.bind(mainMod .. " + SHIFT + B",      exec("~/.config/ml4w/scripts/reload-waybar.sh"))                   -- Reload Waybar
hl.bind(mainMod .. " + CTRL + R",       exec("hyprctl reload"))                                            -- Emergency: reload config, restores all screens
hl.bind(mainMod .. " + W",              exec("~/.local/bin/wallpaper select"))                             -- Pick a wallpaper (colors follow it)
hl.bind(mainMod .. " + SHIFT + W",      exec("~/.local/bin/wallpaper random"))                             -- Random wallpaper
hl.bind(mainMod .. " + L",              exec("loginctl lock-session"))                                     -- Lock the screen (hypridle runs hyprlock)
-- Black lock screen (screen stayed off after resume): works while locked, turns the screens
-- on and restarts hyprlock; the session stays locked
hl.bind(mainMod .. " + CTRL + L",       exec("~/.local/bin/lock-recover --if-locked"), { locked = true })
hl.bind(mainMod .. " + comma",          exec("~/.local/bin/settings"))                                     -- Settings panel (Wi-Fi, Bluetooth, Sound, ...); again closes it
hl.bind(mainMod .. " + Escape",         exec("~/.local/bin/power-menu"))                                   -- Power menu (lock, suspend, hibernate, force quit, ...); again closes it

-- Way out of an app that holds the keyboard (virt-manager / remote desktop in fullscreen send
-- every SUPER key to the guest): dont_inhibit makes this one key reach Hyprland anyway. It
-- leaves fullscreen and goes back to the previous workspace; the app keeps running.
hl.bind(mainMod .. " + CTRL + Escape",
    exec("hyprctl activewindow -j | jq -e '.fullscreen != 0' >/dev/null && hyprctl dispatch 'hl.dsp.window.fullscreen()'; hyprctl dispatch 'hl.dsp.focus({ workspace = \"previous\" })'"),
    { dont_inhibit = true })
hl.bind(mainMod .. " + S",              exec("~/.local/bin/launcher"))                                     -- Same launcher: type, Ctrl+Enter = web search
hl.bind(mainMod .. " + V",              exec("~/.local/bin/clipboard"))                                    -- Clipboard history: pick to paste (Shift+Enter: delete entry)
hl.bind(mainMod .. " + equal",          exec("~/.local/bin/calc"))                                         -- Calculator (rofi-calc): Enter copies the result
hl.bind(mainMod .. " + SHIFT + T",      exec("~/.local/bin/timer"))                                        -- Timers and alarms (countdown on Waybar)
hl.bind(mainMod .. " + SHIFT + C",      exec("~/.local/bin/caffeine toggle"))                              -- Keep awake on/off (no idle lock or suspend)
hl.bind(mainMod .. " + A",              exec("~/.local/bin/cava-toggle"))                                  -- Audio visualizer on/off

-- Lid. With an external monitor plugged in, display-toggle makes it the only screen while
-- the lid is closed (logind does not suspend then). caffeine only acts while it is on
-- (otherwise logind suspends and hypridle locks first).
hl.bind("switch:on:Lid Switch",  exec("~/.local/bin/display-toggle lid-close; ~/.local/bin/caffeine lid-close"), { locked = true })
hl.bind("switch:off:Lid Switch", exec("~/.local/bin/display-toggle lid-open; ~/.local/bin/caffeine lid-open"),   { locked = true })

-- Hardware keys
hl.bind("XF86AudioRaiseVolume",  exec("~/.local/bin/osd volume up"), { repeating = true, locked = true })      -- with popup (bin/osd)
hl.bind("XF86AudioLowerVolume",  exec("~/.local/bin/osd volume down"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessUp",   exec("~/.local/bin/osd brightness up"), { repeating = true })
hl.bind("XF86MonBrightnessDown", exec("~/.local/bin/osd brightness down"), { repeating = true })
hl.bind("XF86AudioMute",         exec("~/.local/bin/osd volume mute"), { locked = true })
hl.bind("XF86AudioMicMute",      exec("~/.local/bin/osd mic mute"))
hl.bind("XF86WLAN",              exec("nmcli radio wifi toggle"))
hl.bind("XF86Refresh",           exec("wtype -k F5"))
hl.bind("XF86SelectiveScreenshot", exec("~/.local/bin/screenshot area"))  -- Fn+F10: select a region -> file + clipboard
hl.bind("XF86Favorites",         exec("~/.local/bin/launcher"))              -- Fn+F12 (star): launcher
hl.bind("XF86Display",           exec("~/.local/bin/display-toggle"))        -- Fn+F7: cycle external monitor mirror -> extended -> off
-- F11 hotkey (phone icon): fullscreen the active window. Newer kernels send it as
-- KEY_LINK_PHONE (XF86LinkPhone); older ones had no keysym for it (keycode 248)
hl.bind("XF86LinkPhone",         hl.dsp.window.fullscreen())
hl.bind("code:248",              hl.dsp.window.fullscreen())
-- Media keys also work on the lock screen (hyprlock shows the song: bin/lock-media)
hl.bind("XF86AudioPlay",         exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",         exec("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev",         exec("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop",         exec("playerctl stop"), { locked = true })

-- Screenshots (~/Pictures/Screenshots) and screen recording (~/Videos/Recordings)
hl.bind("Print",                    exec("~/.local/bin/screenshot full"))   -- Fn+F9 (PrtSc): whole screen -> file + clipboard
hl.bind("SHIFT + Print",            exec("~/.local/bin/screenshot area"))   -- Select a region -> file + clipboard
hl.bind(mainMod .. " + Print",      exec("~/.local/bin/screenshot edit"))   -- Select a region -> annotate in satty
hl.bind(mainMod .. " + SHIFT + R",  exec("~/.local/bin/screenrec area"))    -- Start/stop recording a region
hl.bind(mainMod .. " + ALT + R",    exec("~/.local/bin/screenrec full"))    -- Start/stop recording the whole screen
-- macOS-style capture keys (CTRL instead of SHIFT: SUPER+SHIFT+number moves windows)
hl.bind(mainMod .. " + CTRL + 3",   exec("~/.local/bin/screenshot full"))   -- Whole screen right away
hl.bind(mainMod .. " + CTRL + 4",   exec("~/.local/bin/capture-menu shot")) -- Screenshot toolbar
hl.bind(mainMod .. " + CTRL + 5",   exec("~/.local/bin/capture-menu rec"))  -- Recording toolbar (also stops)

-- Move focus with mainMod + arrow keys; two arrows together (e.g. up + right) focus the
-- floating window in that screen corner (conf/float-move.lua)
local floatMove  = require("conf.float-move")
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. dir, function() floatMove.focus(dir) end)
end

-- Move / resize the active window with the keyboard (hold to repeat)
local resizeStep = 40
local dirs = {
    left  = { x = -1, y = 0 },
    right = { x = 1,  y = 0 },
    up    = { x = 0,  y = -1 },
    down  = { x = 0,  y = 1 },
}
for dir, d in pairs(dirs) do
    -- mainMod + SHIFT + arrow: a floating window glides while the arrow is held
    -- (conf/float-move.lua), a tiled one swaps places with its neighbour
    hl.bind(mainMod .. " + SHIFT + " .. dir, function()
        if not floatMove.press(dir) then
            hl.dispatch(hl.dsp.window.move({ direction = dir }))
        end
    end, { repeating = true })
    -- Stop gliding when the arrow comes up, whatever modifiers are still held
    -- (non_consuming: apps still get the key release)
    hl.bind(dir, function() floatMove.release(dir) end,
        { release = true, ignore_mods = true, non_consuming = true })
    -- mainMod + ALT + arrow: resize
    hl.bind(mainMod .. " + ALT + " .. dir,
        hl.dsp.window.resize({ x = d.x * resizeStep, y = d.y * resizeStep, relative = true }),
        { repeating = true })
end

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad): slides in over the current workspace, again to hide it
hl.bind("CTRL + SHIFT + down", hl.dsp.workspace.toggle_special("scratch"))

-- Previous / next workspace in number order on this monitor (empty ones too):
-- mainMod + CTRL + left / right
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
-- Take the active window along: mainMod + CTRL + SHIFT + left / right
hl.bind(mainMod .. " + CTRL + SHIFT + left",  hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.window.move({ workspace = "r+1" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
