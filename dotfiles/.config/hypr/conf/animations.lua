-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.config({ animations = { enabled = true } })

-- Animation curves
local curves = {
    linear        = { {0, 0},       {1, 1} },
    md3_standard  = { {0.2, 0},     {0, 1} },
    md3_decel     = { {0.05, 0.7},  {0.1, 1} },
    md3_accel     = { {0.3, 0},     {0.8, 0.15} },
    overshot      = { {0.05, 0.9},  {0.1, 1.1} },
    crazyshot     = { {0.1, 1.5},   {0.76, 0.92} },
    hyprnostretch = { {0.05, 0.9},  {0.1, 1.0} },
    menu_decel    = { {0.1, 1},     {0, 1} },
    menu_accel    = { {0.38, 0.04}, {1, 0.07} },
    easeInOutCirc = { {0.85, 0},    {0.15, 1} },
    easeOutCirc   = { {0, 0.55},    {0.45, 1} },
    easeOutExpo   = { {0.16, 1},    {0.3, 1} },
    softAcDecel   = { {0.26, 0.26}, {0.15, 1} },
    md2           = { {0.4, 0},     {0.2, 1} }, -- use with .2s duration
}
for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

-- Animation configs
hl.animation({ leaf = "windows",          enabled = true, speed = 3,   bezier = "md3_decel",  style = "popin 60%" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3,   bezier = "md3_decel",  style = "popin 60%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3,   bezier = "md3_accel",  style = "popin 60%" })
hl.animation({ leaf = "border",           enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3,   bezier = "md3_decel" })
-- hl.animation({ leaf = "layers",        enabled = true, speed = 2,   bezier = "md3_decel",  style = "slide" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3,   bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.6, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2,   bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 4.5, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 7,   bezier = "menu_decel", style = "slide" })
-- hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.5, bezier = "softAcDecel", style = "slide" })
-- hl.animation({ leaf = "workspaces",    enabled = true, speed = 7,   bezier = "menu_decel", style = "slidefade 15%" })
-- hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "md3_decel", style = "slidefadevert 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   bezier = "md3_decel",  style = "slidevert" })
