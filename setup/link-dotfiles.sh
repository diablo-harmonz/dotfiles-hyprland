#!/usr/bin/env bash
# Symlink this repo's dotfiles into $HOME so edits in the repo apply directly.
#   dotfiles/.zshrc           -> ~/.zshrc
#   dotfiles/.zprofile        -> ~/.zprofile (starts Hyprland after a TTY1 login)
#   dotfiles/.config/<name>   -> ~/.config/<name>
#   bin/<script>              -> ~/.local/bin/<script>
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

for src in "$REPO"/bin/*; do
    _link "$src" "$HOME/.local/bin/$(basename -- "$src")"
done

echo ":: Done."
