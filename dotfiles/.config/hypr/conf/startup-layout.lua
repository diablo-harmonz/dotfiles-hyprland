-- Startup layout: floating "widget" windows opened on workspace 1 at login.
-- Each widget is a window rule (size/position in % of the monitor, so it fits the
-- laptop and external screens) plus a command in M.start(), called by autostart.lua.
-- Add more widgets (clock, cava, ...) as new blocks below.
local M = {}

-- Welcome terminal: kitty, top-left, runs fastfetch once (see ~/.zshrc).
-- Other terminals no longer run fastfetch.
hl.window_rule({
    name  = "welcome-terminal",
    match = { class = "^(welcome)$" },

    float = true,
    size  = "(monitor_w*0.38) (monitor_h*0.44)",   -- room for fastfetch (17 lines + prompt)
    move  = "(monitor_w*0.07) (monitor_h*0.17)",
})

function M.start()
    hl.exec_cmd("kitty --class welcome env WELCOME_FASTFETCH=1 zsh")
end

return M
