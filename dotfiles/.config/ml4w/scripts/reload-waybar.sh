#!/usr/bin/env bash
# Restart waybar (SUPER+SHIFT+B), e.g. when it froze: one bar per screen, sized to it
# (bin/waybar-launch). Its log goes to the journal: journalctl --user -t waybar
exec "$HOME/.local/bin/waybar-launch"
