#!/usr/bin/env bash
# Install this repo's pacman hooks (needs sudo).
# The hook runs as root, so its script is copied root-owned out of the home directory;
# a hook that executed a file in $HOME would let any program of this user run code as root.
# Run again after changing the files in setup/pacman-hooks/.
set -euo pipefail
SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/pacman-hooks"
# hyprland-verify-config: Hyprland config after Hyprland upgrades
# rmpc-verify-config:     rmpc config + theme after rmpc upgrades
for name in hyprland-verify-config rmpc-verify-config; do
    sudo install -D -m 755 -o root -g root "$SRC/$name" "/usr/local/lib/dotfiles-hyprland/$name"
    sudo install -D -m 644 -o root -g root "$SRC/$name.hook" "/etc/pacman.d/hooks/$name.hook"
    echo ":: Installed pacman hook: /etc/pacman.d/hooks/$name.hook"
done
