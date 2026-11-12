# Login shell.
# The repo's scripts live in ~/.local/bin (lock-recover, wallpaper, ...). Manjaro adds it
# to PATH in /etc/profile.d, plain Arch does not, so add it here for TTY logins too.
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"

# Logging in on another console while Hyprland's lock screen is stuck (black screen):
# offer the fix right away, so nobody has to remember the lock-recover command.
if [[ $(tty) == /dev/tty[2-9] ]] && pgrep -x hyprlock >/dev/null; then
  print "\nA Hyprland session is locked (maybe a black lock screen)."
  read -q "?Restore its lock screen now? [y/N] " && { print; lock-recover; print "Now press Ctrl+Alt+F1 (or the console Hyprland runs on) and unlock."; }
  print
fi

# After logging in on the first console (TTY1), start Hyprland.
# There is no display manager: log in with user + password on the black screen,
# Hyprland starts, and quitting it (SUPER+M) returns to the login prompt.
# Other consoles (Ctrl+Alt+F2...) stay plain shells for repairs.
# Checks the real terminal, not XDG_VTNR: SDDM (Manjaro) runs its session script as a
# zsh login shell on VT1 too, but without a terminal, so it must not match here.
if [[ $(tty) == /dev/tty1 && -z $WAYLAND_DISPLAY ]] && ! pgrep -x Hyprland >/dev/null; then
  exec start-hyprland
fi
