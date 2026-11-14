#!/usr/bin/env bash
# Install the system-wide pieces of this setup (needs sudo). Safe to run again.
#   - battery charge thresholds 75/80: a oneshot service at boot (setup/system/), and a
#     root-owned helper + polkit action so bin/battery-mode can switch (password each time)
#   - PAM: unlock gnome-keyring with the login password, for the display manager
#     in use (sddm, greetd or the plain console login) and for password changes
#   - zram swap (size = RAM, zstd) and the vm.* sysctls for it
#   - earlyoom: stop the biggest process (test browsers first) before memory runs out
#   - Firefox policy: install uBlock Origin, Proton Pass and Unhook from addons.mozilla.org
#   - firewall (nftables): nothing from the network may connect in; Docker/libvirt keep
#     working (setup/system/nftables.conf)
#   - faillock: 5 wrong passwords -> locked for 2 minutes (default: 3 -> 10 minutes)
#   - Bluetooth: bluetoothd without its GATT battery plugin, so headsets show the
#     battery level they send over HFP (forwarded by PipeWire)
#   - Timeshift (btrfs): daily 5, weekly 3, /home excluded; grub-btrfsd keeps the GRUB
#     snapshot menu up to date; cronie runs the schedule
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- Battery charge thresholds ---
# An older version installed a udev rule that re-triggered itself: remove it
if [ -f /etc/udev/rules.d/99-battery-charge-threshold.rules ]; then
    sudo rm -f /etc/udev/rules.d/99-battery-charge-threshold.rules
    sudo udevadm control --reload
fi
# Root-owned helper (never run a file from $HOME as root) + polkit action for bin/battery-mode
sudo install -D -m 755 -o root -g root "$DIR/system/battery-threshold" \
    /usr/local/lib/dotfiles-hyprland/battery-threshold
sudo install -D -m 644 -o root -g root "$DIR/system/org.dotfiles-hyprland.battery-threshold.policy" \
    /usr/share/polkit-1/actions/org.dotfiles-hyprland.battery-threshold.policy
sudo install -D -m 644 "$DIR/system/battery-charge-threshold.service" \
    /etc/systemd/system/battery-charge-threshold.service
sudo systemctl daemon-reload
sudo systemctl enable --now battery-charge-threshold.service
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
elif ! cmp -s "$DIR/system/zram-generator.conf" /etc/systemd/zram-generator.conf; then
    # Never resize a zram0 in use: swapoff would have to pull everything back into RAM
    sudo install -m 644 "$DIR/system/zram-generator.conf" /etc/systemd/zram-generator.conf
    echo ":: zram: new size applies at the next boot"
fi
sudo install -D -m 644 "$DIR/system/99-vm-zram.conf" /etc/sysctl.d/99-vm-zram.conf
sudo sysctl -q --load /etc/sysctl.d/99-vm-zram.conf
echo ":: zram: $(zramctl --noheadings --output NAME,DISKSIZE,ALGORITHM 2>/dev/null | tr -s ' ' || echo none)"

# --- Firefox extensions (installed by Firefox itself from addons.mozilla.org at start) ---
if command -v firefox >/dev/null; then
    if [ -f /etc/firefox/policies/policies.json ] && ! cmp -s "$DIR/system/firefox-policies.json" /etc/firefox/policies/policies.json; then
        sudo cp /etc/firefox/policies/policies.json /etc/firefox/policies/policies.json.bak-dotfiles
    fi
    sudo install -D -m 644 "$DIR/system/firefox-policies.json" /etc/firefox/policies/policies.json
    echo ":: Firefox policy: uBlock Origin, Proton Pass, Unhook (restart Firefox)"
fi

# --- earlyoom ---
if command -v earlyoom >/dev/null; then
    sudo install -D -m 644 "$DIR/system/earlyoom" /etc/default/earlyoom
    sudo systemctl enable earlyoom.service
    sudo systemctl restart earlyoom.service
    echo ":: earlyoom: $(systemctl is-active earlyoom.service)"
else
    echo ":: earlyoom not installed (sudo pacman -S earlyoom), skipped"
fi

# --- Firewall (nftables) ---
if command -v nft >/dev/null; then
    if ! cmp -s "$DIR/system/nftables.conf" /etc/nftables.conf; then
        [ ! -f /etc/nftables.conf ] || [ -f /etc/nftables.conf.bak-dotfiles ] || \
            sudo cp /etc/nftables.conf /etc/nftables.conf.bak-dotfiles
        sudo nft -c -f "$DIR/system/nftables.conf"   # syntax check before installing
        sudo install -m 644 "$DIR/system/nftables.conf" /etc/nftables.conf
    fi
    # oneshot without RemainAfterExit: it loads the rules and then shows "inactive",
    # so check the table itself
    sudo systemctl enable nftables.service
    sudo systemctl restart nftables.service
    if sudo nft list table inet firewall >/dev/null 2>&1; then
        echo ":: Firewall: loaded"
    else
        echo ":: WARNING: firewall rules not loaded (sudo nft -f /etc/nftables.conf)"
    fi
else
    echo ":: nft not found (sudo pacman -S nftables), firewall skipped"
fi

# --- faillock: wrong passwords (lock screen, sudo, login) ---
if ! cmp -s "$DIR/system/faillock.conf" /etc/security/faillock.conf; then
    [ -f /etc/security/faillock.conf.bak-dotfiles ] || \
        sudo cp /etc/security/faillock.conf /etc/security/faillock.conf.bak-dotfiles
    sudo install -m 644 "$DIR/system/faillock.conf" /etc/security/faillock.conf
    echo ":: faillock: 5 failures -> 2 min lock"
fi

# --- Bluetooth: headset battery from HFP instead of GATT ---
# Takes effect when bluetoothd restarts (Bluetooth devices reconnect) or at the next boot
if ! cmp -s "$DIR/system/bluetooth.service.d/no-gatt-battery.conf" \
        /etc/systemd/system/bluetooth.service.d/no-gatt-battery.conf; then
    sudo install -D -m 644 "$DIR/system/bluetooth.service.d/no-gatt-battery.conf" \
        /etc/systemd/system/bluetooth.service.d/no-gatt-battery.conf
    sudo systemctl daemon-reload
    echo ":: Bluetooth: GATT battery plugin off, applies after: sudo systemctl restart bluetooth"
fi

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
