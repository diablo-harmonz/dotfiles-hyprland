-- restart-finished.lua: no "resume" at the very end of a file.
-- mpv.conf has save-position-on-quit and keep-open=yes together, so quitting a video
-- (or a yt-x "Listen" track) that already played to the end saved its last second;
-- the next play then resumed there and sat paused at 100 %.
-- 1. While the end is reached, quitting does not save the position (seeking back
--    turns saving on again).
-- 2. A file that resumes within its last 5 seconds (state saved before this script)
--    starts again from the beginning and plays. A start time given on purpose
--    (--start) is left alone: it is read once when the script loads, before mpv
--    applies any saved state (which also sets "start").

local saving = mp.get_property_bool("save-position-on-quit")

mp.observe_property("eof-reached", "bool", function(_, eof)
    if not saving then
        return
    end
    mp.set_property_bool("save-position-on-quit", not eof)
end)

local asked_start = mp.get_property("start", "none") ~= "none"

mp.register_event("file-loaded", function()
    if asked_start then
        return
    end
    local pos = mp.get_property_number("time-pos")
    local duration = mp.get_property_number("duration")
    if pos and duration and duration > 10 and pos >= duration - 5 then
        mp.commandv("seek", "0", "absolute")
        mp.set_property_bool("pause", false)
        mp.osd_message("Played to the end last time: starting over")
    end
end)
