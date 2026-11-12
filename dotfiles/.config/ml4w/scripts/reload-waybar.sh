#!/usr/bin/env bash
# Restart waybar (SUPER+SHIFT+B), e.g. when it froze. Its log goes to the journal:
#   journalctl --user -t waybar
pkill -x waybar
sleep 0.5
pkill -9 -x waybar 2>/dev/null || true
setsid -f systemd-cat -t waybar waybar >/dev/null 2>&1
