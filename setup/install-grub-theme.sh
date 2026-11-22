#!/usr/bin/env bash
# install-grub-theme.sh NAME: install the GRUB theme setup/system/grub-theme/NAME (needs
# sudo). Used by install-system-files.sh (Cosmos) and `theme grub` (a theme pack's GRUB).
# Only images, fonts and theme.txt; a broken theme makes GRUB fall back to its text menu.
# grub.cfg is regenerated only when the theme or /etc/default/grub changed. Safe to run again.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NAME=${1:?usage: install-grub-theme.sh NAME}
SRC="$DIR/system/grub-theme/$NAME"
[ -f "$SRC/theme.txt" ] || { echo "install-grub-theme: no theme $SRC" >&2; exit 1; }
if [ ! -f /etc/default/grub ] || ! command -v grub-mkconfig >/dev/null; then
    echo ":: GRUB not found, theme skipped"
    exit 0
fi

changed=0
if ! sudo diff -rq "$SRC" "/boot/grub/themes/$NAME" >/dev/null 2>&1; then
    sudo rm -rf "/boot/grub/themes/$NAME"
    sudo install -d -m 755 /boot/grub/themes
    sudo cp -r "$SRC" "/boot/grub/themes/$NAME"
    changed=1
fi
grub_set() {   # $1 = key, $2 = value: replace the line (commented or not) or append it
    grep -qxF "$1=$2" /etc/default/grub && return 0
    [ -f /etc/default/grub.bak-dotfiles ] || sudo cp /etc/default/grub /etc/default/grub.bak-dotfiles
    if grep -qE "^#?$1=" /etc/default/grub; then
        sudo sed -i -E "s|^#?$1=.*|$1=$2|" /etc/default/grub
    else
        echo "$1=$2" | sudo tee -a /etc/default/grub >/dev/null
    fi
    changed=1
}
grub_set GRUB_THEME "\"/boot/grub/themes/$NAME/theme.txt\""
grub_set GRUB_GFXMODE '1920x1200,auto'   # the panel's size; the themes are laid out for it
if [ "$changed" = 1 ]; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    echo ":: GRUB theme: $NAME (shows at the next boot)"
else
    echo ":: ok       GRUB theme $NAME"
fi
