#!/usr/bin/env bash
# Symlink this repo's dotfiles into $HOME so edits in the repo apply directly.
#   dotfiles/.zshrc           -> ~/.zshrc
#   dotfiles/.zprofile        -> ~/.zprofile (starts Hyprland after a TTY1 login)
#   dotfiles/.config/<name>   -> ~/.config/<name>
#   bin/<script>              -> ~/.local/bin/<script>
#   dotfiles/icons/<icon>.svg -> ~/.local/share/icons/hicolor/scalable/status/<icon>.svg
#   dotfiles/applications/*.desktop -> ~/.local/share/applications/
#   ../wallpapers             -> ~/Pictures/Wallpapers (private repo cloned next to
#                                this one; skipped when it is not there)
# Existing files/dirs that are not already the right symlink are moved to
# <name>.bak-<timestamp>. Safe to run again.

set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)

_link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink -- "$dst")" = "$src" ]; then
        echo ":: ok       $dst"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv -- "$dst" "$dst.bak-$STAMP"
        echo ":: backup   $dst -> $dst.bak-$STAMP"
    fi
    mkdir -p -- "$(dirname -- "$dst")"
    ln -s -- "$src" "$dst"
    echo ":: linked   $dst -> $src"
}

_link "$REPO/dotfiles/.zshrc" "$HOME/.zshrc"
_link "$REPO/dotfiles/.zprofile" "$HOME/.zprofile"

for src in "$REPO"/dotfiles/.config/*; do
    _link "$src" "$HOME/.config/$(basename -- "$src")"
done

# Own icons (dot-matrix OSD icons), found by name through the hicolor theme
for src in "$REPO"/dotfiles/icons/*.svg; do
    _link "$src" "$HOME/.local/share/icons/hicolor/scalable/status/$(basename -- "$src")"
done

# Hidden desktop entries: icons for WezTerm windows with their own class (Waybar taskbar)
for src in "$REPO"/dotfiles/applications/*.desktop; do
    _link "$src" "$HOME/.local/share/applications/$(basename -- "$src")"
done

for src in "$REPO"/bin/*; do
    _link "$src" "$HOME/.local/bin/$(basename -- "$src")"
done

# Wallpapers live in their own private repo next to this one (third-party art
# must not go into this public repo)
WALLPAPERS=$(dirname -- "$REPO")/wallpapers
if [ -d "$WALLPAPERS" ]; then
    _link "$WALLPAPERS" "$HOME/Pictures/Wallpapers"
else
    echo ":: skipped  ~/Pictures/Wallpapers (clone the wallpapers repo to $WALLPAPERS first)"
fi

# Firefox look (FF Ultima + Matugen colours) into the default profile; never fatal
"$REPO/bin/firefox-theme" || echo ":: firefox-theme failed, run it again later"

echo ":: Done."
