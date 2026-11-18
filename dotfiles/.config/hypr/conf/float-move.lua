-- Smooth keyboard move for floating windows (mainMod + SHIFT + arrows, see binds.lua).
--
-- Key repeat (25/s after a 600 ms delay) moved the window in visible jumps. Instead,
-- pressing an arrow starts a timer that moves the window a few px every frame until
-- the arrow is released; speed ramps up the longer it is held. Two arrows held
-- together move diagonally. The window-move animation is switched off while gliding
-- so the window follows the key directly, and switched back on afterwards.

local M = {}

local FRAME_MS   = 16    -- ~60 Hz, the laptop panel's refresh rate
local START_PXS  = 300   -- px per second when the key goes down
local MAX_PXS    = 800   -- px per second after RAMP_MS
local RAMP_MS    = 700
local MAX_MS     = 15000 -- safety stop if a release is ever missed

-- Same as the "windows" animation in animations.lua, which windowsMove inherits
local MOVE_ANIM = { leaf = "windowsMove", enabled = true, speed = 3, bezier = "md3_decel" }

local VEC = {
    left  = { -1, 0 },
    right = { 1,  0 },
    up    = { 0, -1 },
    down  = { 0,  1 },
}

local held    = {}   -- dir -> true while the arrow is down
local timer   = nil
local elapsed = 0
local carryX, carryY = 0, 0
local address = nil  -- window being moved

local function stop()
    held = {}
    if timer then
        timer:set_enabled(false)
        timer = nil
        hl.animation(MOVE_ANIM)
    end
end

local function tick()
    local win = hl.get_active_window()
    if not win or not win.floating or win.address ~= address or elapsed > MAX_MS then
        stop()
        return
    end
    local dx, dy = 0, 0
    for dir in pairs(held) do
        dx, dy = dx + VEC[dir][1], dy + VEC[dir][2]
    end
    if dx == 0 and dy == 0 then
        stop()
        return
    end
    elapsed = elapsed + FRAME_MS
    local t = math.min(elapsed / RAMP_MS, 1)
    local speed = START_PXS + (MAX_PXS - START_PXS) * t * t  -- ease-in
    local step = speed * FRAME_MS / 1000
    -- Keep the fractional px so slow speeds still move evenly
    carryX = carryX + dx * step
    carryY = carryY + dy * step
    local mx = carryX >= 0 and math.floor(carryX) or math.ceil(carryX)
    local my = carryY >= 0 and math.floor(carryY) or math.ceil(carryY)
    carryX, carryY = carryX - mx, carryY - my
    if mx ~= 0 or my ~= 0 then
        hl.dispatch(hl.dsp.window.move({ x = mx, y = my, relative = true }))
    end
end

-- Arrow pressed (also called on key repeat, which is ignored while gliding)
function M.press(dir)
    local win = hl.get_active_window()
    if not win or not win.floating then return false end
    if held[dir] and timer then return true end
    held[dir] = true
    if not timer then
        address = win.address
        elapsed, carryX, carryY = 0, 0, 0
        hl.animation({ leaf = "windowsMove", enabled = false })
        tick()  -- move right away so a short tap still nudges the window
        timer = hl.timer(tick, { timeout = FRAME_MS, type = "repeat" })
    end
    return true
end

-- Arrows pressed for focus in the last CHORD_MS (see M.focus below)
local CHORD_MS   = 300
local focusHeld  = {}  -- dir -> true
local chordTimer = {}  -- dir -> oneshot timer that forgets it

-- Hyprland only fires a release bind for the key pressed last, so with two arrows down
-- the first one's release never arrives. Any arrow release therefore ends the glide
-- (else a diagonal glide would keep going in the forgotten direction), and focus
-- chords use a time window instead of key-up.
function M.release(dir)
    if timer then stop() end
    focusHeld[dir] = nil
end

M.stop = stop

-- mainMod + arrow focus.
--   * Single arrow: Hyprland's own focus move, so tiled windows are visited exactly as
--     before and floating windows never get in the way.
--   * Two arrows pressed together, within CHORD_MS (e.g. mainMod + up + right): focus
--     the floating window in that corner of the screen. A window near the middle (cava) counts for every
--     corner. Order of the two keys does not matter.
--   * From a floating window, if Hyprland finds nothing in that direction (it only
--     looks for window centres in the direction, so a float sitting on a tiled window
--     is a dead end), go to the nearest window that way, or else the one focused last.
local MIDDLE = 0.1  -- fraction of the screen around its centre that counts for every corner
local OPPOSITE = { left = "right", right = "left", up = "down", down = "up" }

local function centre(w)
    return w.at.x + w.size.x / 2, w.at.y + w.size.y / 2
end

local function visible(w, win)
    return w.address ~= win.address and w.mapped and not w.hidden
end

local function focusWindow(w)
    hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
end

-- The other arrow held together with `dir`, if it is at right angles to it
local function diagonalWith(dir)
    for other in pairs(focusHeld) do
        if other ~= dir and other ~= OPPOSITE[dir] then return other end
    end
end

local function remember(dir)
    focusHeld[dir] = true
    if chordTimer[dir] then chordTimer[dir]:set_enabled(false) end
    chordTimer[dir] = hl.timer(function()
        focusHeld[dir] = nil
        chordTimer[dir] = nil
    end, { timeout = CHORD_MS, type = "oneshot" })
end

-- Floating window in the screen corner given by two arrows
local function floatInCorner(win, windows, a, b)
    local mon = win.monitor
    if not mon then return nil end
    local scale = mon.scale or 1
    local mw, mh = mon.width / scale, mon.height / scale
    local mx, my = mon.position.x + mw / 2, mon.position.y + mh / 2
    local vx, vy = VEC[a][1] + VEC[b][1], VEC[a][2] + VEC[b][2]
    local best, bestScore
    for _, w in ipairs(windows) do
        if visible(w, win) and w.floating then
            local x, y = centre(w)
            local ox, oy = (x - mx) / mw, (y - my) / mh  -- -0.5 .. 0.5 from the centre
            if ox * vx >= -MIDDLE and oy * vy >= -MIDDLE then
                -- Furthest into the corner wins; ties go to the most recently focused
                local score = ox * vx + oy * vy - w.focus_history_id * 1e-4
                if not bestScore or score > bestScore then best, bestScore = w, score end
            end
        end
    end
    return best
end

function M.focus(dir)
    local win = hl.get_active_window()
    local other = diagonalWith(dir)
    remember(dir)
    if not win or not win.workspace then
        hl.dispatch(hl.dsp.focus({ direction = dir }))
        return
    end
    local windows = hl.get_workspace_windows(win.workspace.id)

    if other then
        local target = floatInCorner(win, windows, dir, other)
        if target then focusWindow(target) end
        return
    end

    hl.dispatch(hl.dsp.focus({ direction = dir }))
    if not win.floating then return end
    local now = hl.get_active_window()
    if now and now.address ~= win.address then return end

    local cx, cy = centre(win)
    local vx, vy = VEC[dir][1], VEC[dir][2]
    local best, bestScore, recent
    for _, w in ipairs(windows) do
        if visible(w, win) then
            local x, y = centre(w)
            local along = (x - cx) * vx + (y - cy) * vy   -- distance in the arrow's direction
            local across = math.abs((x - cx) * vy - (y - cy) * vx)
            if along > 0 then
                local score = along + 2 * across
                if not bestScore or score < bestScore then best, bestScore = w, score end
            end
            if not recent or w.focus_history_id < recent.focus_history_id then recent = w end
        end
    end
    local target = best or recent
    if target then focusWindow(target) end
end

return M
