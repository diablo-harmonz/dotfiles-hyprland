-- WezTerm config (ported from the previous kitty.conf)
local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({ "FiraCode Nerd Font", "JetBrainsMono Nerd Font" })
config.font_size = 12
config.initial_cols = 110
config.initial_rows = 28
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.window_decorations = "NONE"
config.window_background_opacity = 0.7
config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 2000
config.audible_bell = "Disabled"
config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBar"
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

return config
