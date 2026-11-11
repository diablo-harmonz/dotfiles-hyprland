#!/usr/bin/env bash
# Install this repo's pacman hooks (needs sudo).
# The hook runs as root, so its script is copied root-owned out of the home directory;
# a hook that executed a file in $HOME would let any program of this user run code as root.
# Run again after changing the files in setup/pacman-hooks/.
set -euo pipefail
SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/pacman-hooks"
sudo install -D -m 755 -o root -g root "$SRC/hyprland-verify-config" /usr/local/lib/dotfiles-hyprland/hyprland-verify-config
sudo install -D -m 644 -o root -g root "$SRC/hyprland-verify-config.hook" /etc/pacman.d/hooks/hyprland-verify-config.hook
echo ":: Installed pacman hook: /etc/pacman.d/hooks/hyprland-verify-config.hook"
