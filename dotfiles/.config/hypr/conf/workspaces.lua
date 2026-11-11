-- Fixed workspaces per screen, so a 3-finger swipe works on every screen:
-- 1-5 always on the laptop screen, 6-10 on the external monitor (when one is connected).
-- Workspace swipes stay within the screen under the cursor.
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

local PANEL = "eDP-1"

for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = PANEL, persistent = true, default = (i == 1) })
end

local function bind_external(name)
    for i = 6, 10 do
        hl.workspace_rule({ workspace = tostring(i), monitor = name, persistent = true, default = (i == 6) })
    end
end

-- External monitor already connected at start or config reload
for _, m in ipairs(hl.get_monitors()) do
    if m.name ~= PANEL then
        bind_external(m.name)
        break
    end
end

-- External monitor plugged in later (any port: HDMI-A-1, DP-1, ...)
hl.on("monitor.added", function(m)
    if m.name ~= PANEL then bind_external(m.name) end
end)

-- Swiping past the last workspace of a screen would create workspace 11, 12, ...
hl.config({ gestures = { workspace_swipe_create_new = false } })
