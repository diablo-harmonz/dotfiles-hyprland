-- Cosmos theme: glowing window borders. Loaded last by hyprland.lua from
-- ~/.config/theme/hyprland.lua (bin/theme).

-- The active border's gradient turns slowly (one turn in 10 s). Hyprland redraws the
-- border on every frame while it turns: a little more power use. false = still gradient.
local ROTATE = true

hl.config({ general = { border_size = 2 } })
if ROTATE then
    hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })
end

-- Colors follow the wallpaper: ~/.config/hypr/colors.lua (Matugen) fills _G.matugen and
-- calls this after every wallpaper change.
_G.theme_on_colors = function()
    local c = _G.matugen
    if not c then return end
    hl.config({
        general = {
            col = {
                active_border = { colors = { "rgba(" .. c.primary .. "ff)", "rgba(" .. c.tertiary .. "ff)",
                                             "rgba(" .. c.secondary .. "ff)" }, angle = 45 },
            },
        },
        decoration = {
            shadow = {
                enabled        = true,
                range          = 18,
                render_power   = 2,
                color          = "rgba(" .. c.primary .. "66)",
                color_inactive = "rgba(00000066)",
            },
        },
    })
end
_G.theme_on_colors()
