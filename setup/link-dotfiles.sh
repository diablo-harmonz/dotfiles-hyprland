#!/usr/bin/env bash
# Symlink this repo's dotfiles into $HOME so edits in the repo apply directly.
#   dotfiles/.zshrc           -> ~/.zshrc
#   dotfiles/.zprofile        -> ~/.zprofile (starts Hyprland after a TTY1 login)
#   dotfiles/.config/<name>   -> ~/.config/<name>
#   bin/<script>              -> ~/.local/bin/<script>
#   dotfiles/icons/<icon>.svg -> ~/.local/share/icons/hicolor/scalable/status/<icon>.svg
#   dotfiles/applications/*.desktop -> ~/.local/share/applications/
#   dotfiles/.claude/statusline.sh -> ~/.claude/statusline.sh (Claude Code status line;
#                                the statusLine entry is added to ~/.claude/settings.json
#                                when it has none, the rest of that file is left alone)
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

# Desktop entries for rofi (Music, YouTube)
for src in "$REPO"/dotfiles/applications/*.desktop; do
    _link "$src" "$HOME/.local/share/applications/$(basename -- "$src")"
done

for src in "$REPO"/bin/*; do
    _link "$src" "$HOME/.local/bin/$(basename -- "$src")"
done

# Claude Code status line. settings.json stays out of this public repo (it holds
# personal settings): only the statusLine entry is added, and only when missing.
_link "$REPO/dotfiles/.claude/statusline.sh" "$HOME/.claude/statusline.sh"
CLAUDE_SETTINGS=$HOME/.claude/settings.json
if command -v jq >/dev/null; then
    [ -s "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
    if jq -e '.statusLine' "$CLAUDE_SETTINGS" >/dev/null; then
        echo ":: ok       statusLine in $CLAUDE_SETTINGS"
    else
        tmp=$(mktemp)
        jq '. + {statusLine: {type: "command", command: "~/.claude/statusline.sh", padding: 0}}' \
            "$CLAUDE_SETTINGS" > "$tmp" && mv -- "$tmp" "$CLAUDE_SETTINGS"
        echo ":: added    statusLine in $CLAUDE_SETTINGS"
    fi
else
    echo ":: skipped  Claude Code statusLine (install jq, then run this again)"
fi

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
