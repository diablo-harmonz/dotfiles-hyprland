# Login shell.
# The repo's scripts live in ~/.local/bin (lock-recover, wallpaper, ...). Manjaro adds it
# to PATH in /etc/profile.d, plain Arch does not, so add it here for TTY logins too.
[[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || export PATH="$HOME/.local/bin:$PATH"

# After logging in on the first console (TTY1), start Hyprland.
# There is no display manager: log in with user + password on the black screen,
# Hyprland starts, and quitting it (SUPER+M) returns to the login prompt.
# Other consoles (Ctrl+Alt+F2...) stay plain shells for repairs.
# Checks the real terminal, not XDG_VTNR: SDDM (Manjaro) runs its session script as a
# zsh login shell on VT1 too, but without a terminal, so it must not match here.
if [[ $(tty) == /dev/tty1 && -z $WAYLAND_DISPLAY ]] && ! pgrep -x Hyprland >/dev/null; then
  exec start-hyprland
fi
