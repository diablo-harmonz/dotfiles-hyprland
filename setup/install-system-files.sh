#!/usr/bin/env bash
# Install the system-wide pieces of this setup (needs sudo). Safe to run again.
#   - udev rule: battery charge thresholds 75/80 (setup/system/)
#   - PAM: unlock gnome-keyring with the login password, for the display manager
#     in use (sddm, greetd or the plain console login) and for password changes
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- Battery charge thresholds ---
sudo install -D -m 644 "$DIR/system/99-battery-charge-threshold.rules" \
    /etc/udev/rules.d/99-battery-charge-threshold.rules
sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=power_supply --sysname-match=BAT0 --action=change
echo ":: Battery thresholds: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null)-$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null)"

# --- gnome-keyring unlocked at login ---
# Adds "<type> optional pam_gnome_keyring.so [args]" after the last line of that type.
pam_add() {   # $1 = file, $2 = type, $3 = args
    local f="$1" type="$2" args="$3"
    [ -f "$f" ] || return 0
    if sudo grep -qE "^${type}\s+optional\s+pam_gnome_keyring\.so" "$f"; then
        echo ":: ok       $f ($type)"
        return 0
    fi
    [ -f "$f.bak-keyring" ] || sudo cp -- "$f" "$f.bak-keyring"
    sudo awk -v type="$type" -v line="$(printf '%s\t\toptional\tpam_gnome_keyring.so%s' "$type" "${args:+ $args}")" '
        { lines[NR] = $0; if ($1 == type) last = NR }
        END { for (i = 1; i <= NR; i++) { print lines[i]; if (i == last) print line }
              if (!last) print line }' "$f" | sudo tee "$f.new" >/dev/null
    sudo mv -- "$f.new" "$f"
    echo ":: added    $f ($type)"
}

login_pam=""
for f in /etc/pam.d/sddm /etc/pam.d/greetd /etc/pam.d/login; do
    if [ -f "$f" ]; then login_pam="$f"; break; fi
done
if [ -n "$login_pam" ]; then
    pam_add "$login_pam" auth ""
    pam_add "$login_pam" session "auto_start"
else
    echo ":: WARNING: no sddm/greetd/login PAM file found, gnome-keyring will not unlock at login"
fi
# Keep the keyring password in sync when the login password changes
pam_add /etc/pam.d/passwd password "use_authtok"
