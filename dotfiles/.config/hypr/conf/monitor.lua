-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- bin/display-toggle (Fn+F7) turns the external monitor off and on itself and marks that
-- with this file; its own monitor events must not trigger the handlers below.
local busy_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/display-toggle.busy"
local function display_toggle_busy()
    local f = io.open(busy_file, "r")
    if f then f:close() return true end
    return false
end

-- Safety net: when a monitor is really unplugged, make sure the laptop screen is on,
-- not mirrored and at its own resolution, so the machine never ends up without a screen.
hl.on("monitor.removed", function()
    if display_toggle_busy() then return end
    hl.monitor({
        output   = "eDP-1",
        mode     = "preferred",
        position = "auto",
        scale    = 1,
        disabled = false, -- must be explicit: Hyprland keeps the earlier disabled = true
        mirror   = "",
    })
    -- display-toggle turns damage tracking off while mirroring; back to the default
    hl.config({ debug = { damage_tracking = 2 } })
    -- the notification daemon can crash when the screen showing a notification goes away; restart it
    hl.exec_cmd("sleep 2; pgrep -x swaync >/dev/null || swaync")
    -- Unplugged while locked (e.g. lid closed at work, opened at home): the laptop screen
    -- can stay off (DPMS) and hyprlock does not redraw for the changed screen, so the lock
    -- screen is black. Turn the screens on and restart hyprlock (the session stays locked).
    hl.dispatch(hl.dsp.dpms("on"))
    hl.exec_cmd("sleep 1; ~/.local/bin/lock-recover --if-locked")
    -- remember when it happened: a monitor that comes back within a few seconds only
    -- dropped out (some do after a mode change) and display-toggle restores its mode
    hl.exec_cmd('date +%s > "$XDG_RUNTIME_DIR/display-toggle.unplugged"')
end)

-- A monitor connected: restore the Fn+F7 mode after a short drop-out, otherwise start
-- the Fn+F7 cycle again at its first step (mirror)
hl.on("monitor.added", function()
    if display_toggle_busy() then return end
    hl.exec_cmd("sleep 1; ~/.local/bin/display-toggle replug")
end)
