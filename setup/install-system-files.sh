#!/usr/bin/env bash
# Install the system-wide pieces of this setup (needs sudo). Safe to run again.
#   - udev rule: battery charge thresholds 75/80 (setup/system/)
#   - PAM: unlock gnome-keyring with the login password, for the display manager
#     in use (sddm, greetd or the plain console login) and for password changes
#   - zram swap (half the RAM, zstd)
#   - Timeshift (btrfs): daily 5, weekly 3, /home excluded; grub-btrfsd keeps the GRUB
#     snapshot menu up to date; cronie runs the schedule
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

# --- zram ---
if [ ! -f /etc/systemd/zram-generator.conf ]; then
    sudo install -D -m 644 "$DIR/system/zram-generator.conf" /etc/systemd/zram-generator.conf
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service || true
fi
echo ":: zram: $(zramctl --noheadings --output NAME,DISKSIZE,ALGORITHM 2>/dev/null | tr -s ' ' || echo none)"

# --- Timeshift + GRUB snapshot menu ---
if command -v timeshift >/dev/null; then
    if [ ! -f /etc/timeshift/timeshift.json ]; then
        # backup device = the btrfs filesystem of /, parent = the LUKS partition under it
        fs_uuid=$(findmnt -no UUID /)
        root_dev=$(findmnt -no SOURCE / | sed 's/\[.*//')
        parent_uuid=""
        if crypt_dev=$(sudo cryptsetup status "$(basename -- "$root_dev")" 2>/dev/null | awk '$1 == "device:" {print $2}') && [ -n "$crypt_dev" ]; then
            parent_uuid=$(sudo blkid -s UUID -o value "$crypt_dev")
        fi
        sudo install -d -m 755 /etc/timeshift
        sed -e "s/@FS_UUID@/$fs_uuid/" -e "s/@PARENT_UUID@/$parent_uuid/" \
            "$DIR/system/timeshift.json" | sudo tee /etc/timeshift/timeshift.json >/dev/null
        echo ":: Timeshift configured for $fs_uuid"
    else
        echo ":: ok       /etc/timeshift/timeshift.json"
    fi
    sudo install -D -m 644 "$DIR/system/grub-btrfsd.service.d/timeshift.conf" \
        /etc/systemd/system/grub-btrfsd.service.d/timeshift.conf
    sudo systemctl daemon-reload
    sudo systemctl enable --now cronie.service grub-btrfsd.service
fi
