-- See https://wiki.hypr.land/Configuring/Basics/Variables/
-- Window corners from the design tokens (bin/tokens); 8 if the file is not there yet
local ok, tokens = pcall(dofile, os.getenv("HOME") .. "/.config/theme-tokens/tokens.lua")
if not ok or type(tokens) ~= "table" then tokens = {} end

hl.config({
    decoration = {
        rounding = tokens.radius_lg or 8,
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
        },
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },
    },
})
