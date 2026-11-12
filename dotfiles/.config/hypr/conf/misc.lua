hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        -- Let a new hyprlock take over a locked session (when the old one died or
        -- shows a black screen); see bin/lock-recover
        allow_session_lock_restore = true,
        -- Any key or mouse movement turns screens back on after DPMS off (Hyprland's
        -- default ignores them, which left a black lock screen until a TTY rescue)
        key_press_enables_dpms   = true,
        mouse_move_enables_dpms  = true,
    },
})
