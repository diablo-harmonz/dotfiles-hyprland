-- hide-launcher.lua: while mpv shows a video, hide the terminal that started it; bring
-- it back (same workspace, focused) when mpv quits. Used by yt-x: its config passes
--   --script-opts=hide_launcher-enabled=yes
-- so mpv started any other way is not affected. Audio only (yt-x "Listen", no video
-- window) keeps the terminal visible, it is the only place to control playback.
-- The terminal goes to Hyprland's hidden workspace "special:ytx" (not shown on screen).

local opts = { enabled = false, workspace = "special:ytx" }
require("mp.options").read_options(opts, "hide_launcher")
if not opts.enabled then
    return
end

local utils = require("mp.utils")

local function run(args)
    local r = mp.command_native({
        name = "subprocess", args = args, capture_stdout = true,
        capture_stderr = true, playback_only = false,
    })
    return (r and r.stdout) or ""
end

local function dispatch(lua)
    run({ "hyprctl", "dispatch", lua })
end

local function parent_of(pid)
    local f = io.open("/proc/" .. pid .. "/stat", "r")
    if not f then return nil end
    local stat = f:read("*l")
    f:close()
    -- "pid (comm) state ppid ...": comm may contain spaces, so match after the last ')'
    local ppid = stat and stat:match("%)%s+%S+%s+(%d+)")
    return ppid and tonumber(ppid) or nil
end

-- The Hyprland window of the closest ancestor process that owns one (kitty running yt-x)
local function launcher_window()
    local clients = utils.parse_json(run({ "hyprctl", "-j", "clients" })) or {}
    local by_pid = {}
    for _, c in ipairs(clients) do
        by_pid[c.pid] = c
    end
    local pid = parent_of(utils.getpid())
    for _ = 1, 15 do
        if not pid or pid <= 1 then return nil end
        if by_pid[pid] then return by_pid[pid] end
        pid = parent_of(pid)
    end
    return nil
end

local hidden = nil   -- { address, workspace }

local function hide()
    if hidden then return end
    local win = launcher_window()
    if not win or not win.workspace or (win.workspace.name or ""):match("^special") then
        return
    end
    hidden = { address = win.address, workspace = win.workspace.id }
    dispatch(string.format('hl.dsp.window.move({ workspace = "%s", window = "address:%s", follow = false })',
        opts.workspace, hidden.address))
end

local function restore()
    if not hidden then return end
    dispatch(string.format('hl.dsp.window.move({ workspace = %d, window = "address:%s", follow = false })',
        hidden.workspace, hidden.address))
    dispatch(string.format('hl.dsp.focus({ window = "address:%s" })', hidden.address))
    hidden = nil
end

-- hide once a video window is really there (not for audio only)
mp.observe_property("vo-configured", "bool", function(_, configured)
    if configured then hide() end
end)
mp.register_event("shutdown", restore)
