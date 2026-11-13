--  _   _                  _                 _
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|
--
-- -----------------------------------------------------
-- Full documentation https://wiki.hypr.land
-- Modules live in ./conf/*.lua and are loaded with require("conf.<name>")

require("conf.monitor")
require("conf.workspaces")
require("conf.autostart")
require("conf.cursor")
require("conf.environments")
require("conf.input")
require("conf.general")
require("conf.decoration")
require("conf.animations")
require("conf.layouts")
require("conf.gestures")
require("conf.misc")
require("conf.windowrules")
require("conf.startup-layout")   -- widget windows; opened by autostart.lua
require("conf.binds")
