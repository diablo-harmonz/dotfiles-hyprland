#!/usr/bin/env bash
# arch-boot-in-root.sh: after archinstall, move /boot (kernel + initramfs) into the
# encrypted btrfs root, like the Manjaro install. Then every Timeshift snapshot holds
# the kernel together with its modules, so restoring or booting an old snapshot from
# the GRUB menu (grub-btrfs) always works, also across kernel updates.
#
# Run it ONCE, as root, inside the new system right after archinstall finishes
# (answer "yes" when archinstall offers to chroot into the installation, or run
# `arch-chroot /mnt` from the live USB). Expected archinstall choices:
#   bootloader GRUB, btrfs with the default subvolumes, LUKS encryption,
#   EFI partition mounted at /boot (the archinstall default).
#
# What it does:
#   1. LUKS key slots -> PBKDF2 (GRUB cannot open Argon2 slots); asks for the passphrase
#   2. adds /crypto_keyfile.bin to LUKS and to the initramfs, so the passphrase is typed
#      only once (in GRUB); the initramfs then lives inside the encrypted root
#   3. copies the kernel and initramfs into /boot on the root subvolume and mounts the
#      EFI partition at /boot/efi instead (fstab updated)
#   4. GRUB_ENABLE_CRYPTODISK=y, menu shown 5 s, reinstalls GRUB, regenerates the configs
#   5. checks the result before you reboot
# A copy of the old /boot is kept in /root/esp-boot-backup-<time>.
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

# --- Safety checks: only on a fresh Arch install with the expected layout ---
[ "$(id -u)" = 0 ] || die "run as root (inside arch-chroot)"
. /etc/os-release
[ "${ID:-}" = arch ] || die "this is ${ID:-unknown}, not Arch; refusing to touch the boot setup"
[ "$(findmnt -no FSTYPE /)" = btrfs ] || die "/ is not btrfs"
[ "$(findmnt -no FSTYPE /boot 2>/dev/null)" = vfat ] \
    || die "/boot is not the EFI partition (already converted, or a different layout)"
pacman -Q grub efibootmgr >/dev/null 2>&1 || die "GRUB not installed: choose GRUB in archinstall"

root_src=$(findmnt -no SOURCE /)              # /dev/mapper/<name>[/@]
mapper=${root_src%%\[*}
crypt_name=$(basename -- "$mapper")
luks_dev=$(cryptsetup status "$crypt_name" | awk '$1 == "device:" {print $2}')
[ -n "$luks_dev" ] || die "/ is not on a LUKS device"
luks_uuid=$(blkid -s UUID -o value "$luks_dev")
esp_dev=$(findmnt -no SOURCE /boot)
esp_uuid=$(blkid -s UUID -o value "$esp_dev")
hooks=$(grep -E '^HOOKS=' /etc/mkinitcpio.conf)

cat <<EOT
Root:      $root_src  (LUKS $luks_dev, UUID $luks_uuid)
EFI:       $esp_dev   (UUID $esp_uuid), now at /boot -> will move to /boot/efi
Initramfs: $hooks
EOT
read -r -p "Type YES to convert the boot setup: " answer
[ "$answer" = YES ] || die "cancelled"

# --- 1. LUKS key slots readable by GRUB ---
step "LUKS key slots: Argon2 -> PBKDF2 (enter the LUKS passphrase when asked)"
while cryptsetup luksDump "$luks_dev" | grep -q 'PBKDF:.*argon2'; do
    cryptsetup luksConvertKey --pbkdf pbkdf2 "$luks_dev"
done
cryptsetup luksDump "$luks_dev" | grep -E 'PBKDF:'

# --- 2. Keyfile in the initramfs: type the passphrase only once ---
step "Keyfile /crypto_keyfile.bin"
if [ ! -f /crypto_keyfile.bin ]; then
    ( umask 077; dd if=/dev/urandom of=/crypto_keyfile.bin bs=512 count=4 status=none )
    echo "Enter the LUKS passphrase to add the keyfile:"
    cryptsetup luksAddKey --pbkdf pbkdf2 "$luks_dev" /crypto_keyfile.bin
fi
chmod 600 /crypto_keyfile.bin
if ! grep -qE '^FILES=\(.*crypto_keyfile\.bin' /etc/mkinitcpio.conf; then
    sed -i -E 's|^FILES=\((.*)\)|FILES=(\1 /crypto_keyfile.bin)|; s|^FILES=\( |FILES=(|' /etc/mkinitcpio.conf
fi
grep -E '^FILES=' /etc/mkinitcpio.conf
if grep -qw sd-encrypt <<<"$hooks"; then
    # systemd initramfs: point it at the keyfile (the encrypt hook finds it by itself)
    if ! grep -q 'rd.luks.key=' /etc/default/grub; then
        sed -i -E "s|^GRUB_CMDLINE_LINUX=\"(.*)\"|GRUB_CMDLINE_LINUX=\"\1 rd.luks.key=$luks_uuid=/crypto_keyfile.bin\"|" /etc/default/grub
    fi
elif ! grep -qw encrypt <<<"$hooks"; then
    die "neither encrypt nor sd-encrypt in HOOKS; check /etc/mkinitcpio.conf"
fi

# --- 3. Kernel + initramfs into the encrypted root, EFI partition at /boot/efi ---
step "Moving /boot into the root subvolume"
backup="/root/esp-boot-backup-$(date +%Y%m%d-%H%M%S)"
cp -a /boot "$backup"
umount /boot
[ -z "$(ls -A /boot 2>/dev/null)" ] || die "/boot on the root subvolume is not empty: $(ls -A /boot)"
cp -a "$backup"/vmlinuz-* /boot/
cp -a "$backup"/*-ucode.img /boot/ 2>/dev/null || true
mkdir -p /boot/efi
mount "$esp_dev" /boot/efi
cp /etc/fstab "/etc/fstab.bak-boot"
# The EFI line may name the partition by UUID, PARTUUID or path: match mount point + type
awk '$2 == "/boot" && $3 == "vfat" { $2 = "/boot/efi" } { print }' /etc/fstab.bak-boot > /etc/fstab
grep -E '/boot/efi' /etc/fstab || die "fstab not updated (see /etc/fstab.bak-boot)"
# The old kernel, initramfs and GRUB files on the EFI partition are no longer used
rm -f /boot/efi/vmlinuz-* /boot/efi/initramfs-* /boot/efi/*-ucode.img
rm -rf /boot/efi/grub

# --- 4. GRUB that unlocks LUKS itself ---
step "GRUB"
set_grub() {   # $1 = key, $2 = value
    if grep -qE "^#?$1=" /etc/default/grub; then
        sed -i -E "s|^#?$1=.*|$1=$2|" /etc/default/grub
    else
        echo "$1=$2" >> /etc/default/grub
    fi
}
set_grub GRUB_ENABLE_CRYPTODISK y
set_grub GRUB_TIMEOUT 5
set_grub GRUB_TIMEOUT_STYLE menu
mkinitcpio -P
chmod 600 /boot/initramfs-*.img
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# --- 5. Check before rebooting ---
step "Checks"
ok=true
check() { if eval "$2"; then echo "  ok    $1"; else echo "  FAIL  $1"; ok=false; fi; }
check "EFI partition mounted at /boot/efi"   '[ "$(findmnt -no SOURCE /boot/efi)" = "$esp_dev" ]'
check "kernel in the encrypted root"         'ls /boot/vmlinuz-* >/dev/null 2>&1 && [ "$(findmnt -no FSTYPE -T /boot)" = btrfs ]'
check "GRUB EFI binary installed"            '[ -f /boot/efi/EFI/GRUB/grubx64.efi ]'
check "GRUB unlocks LUKS (cryptomount)"      'grep -aq cryptomount /boot/efi/EFI/GRUB/grubx64.efi'
check "grub.cfg has a boot entry"            'grep -q "vmlinuz" /boot/grub/grub.cfg'
check "keyfile inside the initramfs"         'lsinitcpio "$(ls /boot/initramfs-*.img | grep -v fallback | head -1)" | grep -q crypto_keyfile.bin'
check "no LUKS key slot left on Argon2"      '! cryptsetup luksDump "$luks_dev" | grep -q "PBKDF:.*argon2"'
echo
if $ok; then
    echo ":: Done. Exit the chroot, unmount and reboot. GRUB asks for the LUKS passphrase once."
    echo ":: Old /boot kept in $backup (delete it after a successful boot)."
else
    echo ":: Some checks failed: do NOT reboot yet. Old /boot is in $backup, old fstab in /etc/fstab.bak-boot."
    exit 1
fi
