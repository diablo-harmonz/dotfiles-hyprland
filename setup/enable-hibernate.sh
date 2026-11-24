#!/usr/bin/env bash
# enable-hibernate.sh: "suspend-then-hibernate" in docs/plan.md (steps 1-3 and 5).
# Adds a btrfs swapfile in its own @swap subvolume (zram stays the main swap), points the
# kernel at it (resume= / resume_offset=), adds the resume hook to the initramfs, and
# installs the lid config: lid closed -> suspend, hibernate after 30 min
# (setup/system/logind.conf.d/lid.conf, setup/system/sleep.conf.d/hibernate.conf).
# setup-arch.sh asks to run it. Safe to run again: every step checks whether it is done.
# Run as root: sudo bash setup/enable-hibernate.sh   (then reboot, then: systemctl hibernate)
set -euo pipefail

SYSTEM_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/system"
# Swapfile = RAM (rounded up to whole GiB) + 5 GiB; 16 GB RAM -> 20g. More RAM later:
# swapoff, delete the file, run this again.
SWAP_SIZE=$(( ($(awk '/^MemTotal:/ {print $2}' /proc/meminfo) + 1048575) / 1048576 + 5 ))g
SWAP_DIR=/swap
SWAP_FILE=$SWAP_DIR/swapfile
TOP=/mnt/btrfs-top

[ "$(id -u)" = 0 ] || { echo "Run with sudo." >&2; exit 1; }
grep -qw disk /sys/power/state || {
    echo "The kernel cannot hibernate (no 'disk' in /sys/power/state; Secure Boot lockdown?)." >&2
    exit 1
}

FS_UUID=$(findmnt -no UUID /)
FS_DEV=$(findmnt -no SOURCE / | sed 's/\[.*//')
[ "$(findmnt -no FSTYPE /)" = btrfs ] || { echo "Root is not btrfs." >&2; exit 1; }
echo "==> Root filesystem: $FS_DEV (UUID $FS_UUID)"

# 0. Safety net: Timeshift snapshot and backups of the files changed below
if command -v timeshift >/dev/null && [ -f /etc/timeshift/timeshift.json ]; then
    echo "==> Timeshift snapshot"
    timeshift --create --comments "before enable-hibernate" --scripted
fi
STAMP=$(date +%Y%m%d-%H%M%S)
for f in /etc/fstab /etc/default/grub /etc/mkinitcpio.conf; do
    cp -a "$f" "$f.bak-hibernate-$STAMP"
done
echo "==> Backups: *.bak-hibernate-$STAMP"

# 1. @swap subvolume next to @ and @home (Timeshift skips it)
mkdir -p "$TOP"
mount -o subvolid=5 "$FS_DEV" "$TOP"
if [ ! -d "$TOP/@swap" ]; then
    echo "==> Creating subvolume @swap"
    btrfs subvolume create "$TOP/@swap"
fi
umount "$TOP"
rmdir "$TOP"

mkdir -p "$SWAP_DIR"
if ! grep -qE "^[^#].*[[:space:]]$SWAP_DIR[[:space:]]" /etc/fstab; then
    echo "==> fstab: mount @swap on $SWAP_DIR"
    printf '\nUUID=%s\t%s\tbtrfs\trw,noatime,subvol=/@swap\t0 0\n' "$FS_UUID" "$SWAP_DIR" >> /etc/fstab
fi
systemctl daemon-reload
mountpoint -q "$SWAP_DIR" || mount "$SWAP_DIR"

if [ ! -f "$SWAP_FILE" ]; then
    echo "==> Creating $SWAP_SIZE swapfile"
    btrfs filesystem mkswapfile --size "$SWAP_SIZE" --uuid clear "$SWAP_FILE"
fi

# 2. Low priority: zram (prio 100) is still used first in normal work
if ! grep -qE "^[^#]*$SWAP_FILE[[:space:]]" /etc/fstab; then
    echo "==> fstab: swapfile with pri=-2"
    printf '%s\tnone\tswap\tdefaults,pri=-2\t0 0\n' "$SWAP_FILE" >> /etc/fstab
fi
swapon --show=NAME --noheadings | grep -qx "$SWAP_FILE" || swapon "$SWAP_FILE"

# 3. Kernel resume location + initramfs hook
OFFSET=$(btrfs inspect-internal map-swapfile -r "$SWAP_FILE")
echo "==> resume=UUID=$FS_UUID resume_offset=$OFFSET"
sed -i -E '/^GRUB_CMDLINE_LINUX_DEFAULT=/{
    s/ ?resume(_offset)?=[^ "]*//g
    s/"$/ resume=UUID='"$FS_UUID"' resume_offset='"$OFFSET"'"/
}' /etc/default/grub

# A systemd-based initramfs (HOOKS with "systemd", e.g. sd-encrypt) resumes by itself; the
# classic one needs "resume" after "encrypt" (LUKS open first), before "filesystems".
if grep -qE '^HOOKS=.*\bsystemd\b' /etc/mkinitcpio.conf; then
    echo "==> mkinitcpio: systemd initramfs, no resume hook needed"
elif ! grep -qE '^HOOKS=.*\bresume\b' /etc/mkinitcpio.conf; then
    if grep -qE '^HOOKS=.*\bencrypt\b' /etc/mkinitcpio.conf; then
        echo "==> mkinitcpio: add resume hook after encrypt"
        sed -i -E '/^HOOKS=/s/\bencrypt\b/encrypt resume/' /etc/mkinitcpio.conf
    else
        echo "==> mkinitcpio: add resume hook before filesystems"
        sed -i -E '/^HOOKS=/s/\bfilesystems\b/resume filesystems/' /etc/mkinitcpio.conf
    fi
    grep -qE '^HOOKS=.*\bresume\b' /etc/mkinitcpio.conf \
        || { echo "Could not add the resume hook, check HOOKS in /etc/mkinitcpio.conf" >&2; exit 1; }
fi

echo "==> Rebuilding initramfs"
mkinitcpio -P
echo "==> Rebuilding GRUB config"
grub-mkconfig -o /boot/grub/grub.cfg

# 5. Lid closed: suspend, hibernate after 30 min (HUP = reload logind's config; a restart
#    would end the running session)
for f in logind.conf.d/lid.conf sleep.conf.d/hibernate.conf; do
    install -D -m 644 "$SYSTEM_DIR/$f" "/etc/systemd/$f"
done
systemctl kill -s HUP systemd-logind
echo "==> Lid: suspend, then hibernate after 30 min"

echo
echo "==> Result"
swapon --show
grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
grep -E '^HOOKS=' /etc/mkinitcpio.conf
echo
echo "Done. Reboot, then test with: systemctl hibernate"
