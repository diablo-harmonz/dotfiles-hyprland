#!/usr/bin/env bash

# ----------------------------------------------------------
# Packages
# ----------------------------------------------------------

packages=(
    "wget"
    "unzip"
    "git"
    "gum"    
    "hyprland"
    "waybar"
    "rofi"
    "kitty"
    "swaync"
    "hyprpolkitagent"
    "qt6ct"
    "cliphist"
    "rofi-calc"                 # calculator in rofi (SUPER+=), pulls libqalculate (qalc)
    "sound-theme-freedesktop"   # alarm sound for bin/timer
    "python-gobject"
    "gtk4-layer-shell"
    "network-manager-applet"   # nm-connection-editor (VPN, advanced settings); no tray icon
    "bluez"
    "bluez-utils"
    "nautilus"
    "nautilus-open-any-terminal"
    "sushi"                       # Nautilus Quick Look: select a file, press Space
    "xdg-desktop-portal-hyprland"
    "qt5-wayland"
    "qt6-wayland"
    "awww"
    "quickshell"                # wallpaper carousel, SUPER+W (dotfiles/.config/quickshell/wallpicker)
    "matugen"
    "imagemagick"
    "hyprlock"
    "hypridle"
    "hyprsunset"
    "firefox"
    "woff2-font-awesome"
    "vim"
    "zsh"
    "fastfetch"
    "cava"
    "ttf-fira-sans" 
    "ttf-fira-code" 
    "ttf-firacode-nerd"
    "jq"
    "brightnessctl"
    "playerctl"
    "grim"
    "slurp"
    "wl-clipboard"
    "satty"
    "wf-recorder"
    "wtype"
    "networkmanager"
    "wireplumber"
    "pipewire"
    "pipewire-pulse"
    "pipewire-audio"     # pw-play: the bin/timer alarm sound
    "alsa-utils"         # amixer: bin/osd keeps the mic-mute LED in sync
    "xdg-desktop-portal-gtk"
    "gnome-keyring"
    "seahorse"
    "libsecret"
    "libnotify"
    "upower"
    "power-profiles-daemon"
    "lm_sensors"
    "papirus-icon-theme"
    "noto-fonts"
    "smartmontools"
    "yazi"
    "neovim"
    "lazygit"
    "ffmpegthumbnailer"
    "fd"
    "fzf"
    "zoxide"
    "eza"
    "navi"
    "tealdeer"
    "wiremix"
    "mpv"
    "mpv-mpris"
    "yt-dlp"
    "python-mutagen"            # yt-dlp: embed tags and the cover into .opus (bin/yt-music)
    "yt-x"
    "chafa"
    "mpd"
    "mpd-mpris"
    "rmpc"
    "bluetui"
    "resvg"
    "tree-sitter-cli"
    "ripgrep"
    "poppler"
    "7zip"
    "btop"
    "zram-generator"
    "earlyoom"
    "nftables"
    "timeshift"
    "timeshift-autosnap"
    "pacman-contrib"     # checkupdates, pacdiff (bin/sysupdate)
    "reflector"          # sysupdate ranks the mirrors again when the first one is slow
    "grub-btrfs"
    "inotify-tools"
    "cronie"
    "adw-gtk-theme"
    "breeze-cursors"
    "xdg-user-dirs"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "zsh-history-substring-search"
    "zsh-completions"
    "zsh-theme-powerlevel10k"
    "noto-fonts-emoji"
    "noto-fonts-cjk"     # Japanese/Chinese/Korean text (yt-x search placeholder, web pages, subtitles)
    "wlogout"
    "archlinux-wallpaper"   # first wallpapers until the private wallpapers repo is cloned (bin/wallpaper)
    "fcitx5"
    "fcitx5-gtk"
    "fcitx5-qt"
    "fcitx5-configtool"
    "fcitx5-lotus"
    "fcitx5-bamboo"
    # Development: Node through nvm (.zshrc loads it), Python per project through uv
    "nvm"
    "uv"
    "docker"
    "docker-compose"
    "docker-buildx"
    # Chat
    "telegram-desktop"   # translucent in Hyprland (windowrules.lua)
    "discord"
)

# ----------------------------------------------------------
# Colors
# ----------------------------------------------------------

GREEN='\033[0;32m'
NONE='\033[0m'

# ----------------------------------------------------------
# Check if command exists
# ----------------------------------------------------------

_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
        return
    fi
    echo 0
    return
}

# ----------------------------------------------------------
# Check if package is already installed
# ----------------------------------------------------------

_isInstalled() {
    package="$1"
    check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")"
    if [ -n "${check}" ]; then
        echo 0
        return #true
    fi
    echo 1
    return #false
}

# ----------------------------------------------------------
# Install yay
# ----------------------------------------------------------

_installYay() {
    sudo pacman -S --needed --noconfirm base-devel git || exit 1
    download_folder=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$download_folder/yay" || exit 1
    (cd "$download_folder/yay" && makepkg -si) || exit 1
    rm -rf "$download_folder"
    echo ":: yay has been installed successfully."
}

# ----------------------------------------------------------
# Install packages
# ----------------------------------------------------------

_installPackages() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        echo "Package not installed: ${pkg}"
        yay --noconfirm -S "${pkg}"
    done
}

# ----------------------------------------------------------
# Header
# ----------------------------------------------------------

clear
echo -e "${GREEN}"
cat <<"EOF"
   ____    __          
  / __/__ / /___ _____ 
 _\ \/ -_) __/ // / _ \
/___/\__/\__/\_,_/ .__/
                /_/    
ML4W Hyprland Starter for Arch based distros

EOF
echo -e "${NONE}"

# ----------------------------------------------------------
# Content
# ----------------------------------------------------------

while true; do
    read -p "DO YOU WANT TO START THE PACKAGE INSTALLATION NOW? (Yy/Nn): " yn
    case $yn in
        [Yy]*)
            echo ":: Installation started."
            echo
            break
            ;;
        [Nn]*)
            echo ":: Installation canceled"
            exit
            break
            ;;
        *)
            echo ":: Please answer yes or no."
            ;;
    esac
done

# Install yay if needed
if [[ $(_checkCommandExists "yay") == 0 ]]; then
    echo ":: yay is already installed"
else
    echo ":: The installer requires yay. yay will be installed now"
    _installYay
fi

# Packages
_installPackages "${packages[@]}"

# Lotus input method: its uinput server sends the backspaces that fix Vietnamese marks
sudo systemctl enable --now "fcitx5-lotus-server@$USER.service"

# Nautilus: "Open in Terminal" opens kitty
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty

# Qt apps: Fusion style with the Matugen palette (qt6ct needs an absolute path)
mkdir -p ~/.config/qt6ct/colors
[ -f ~/.config/qt6ct/qt6ct.conf ] || cat > ~/.config/qt6ct/qt6ct.conf <<EOT
[Appearance]
color_scheme_path=$HOME/.config/qt6ct/colors/matugen.conf
custom_palette=true
icon_theme=Papirus-Dark
standard_dialogs=default
style=Fusion
EOT

# GTK: dark adw-gtk3 theme for GTK 3 apps (Nautilus dialogs, nm-applet...), Matugen colors
# for GTK 3 and GTK 4, Papirus icons, Breeze cursor, Noto Sans
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
for v in 3.0 4.0; do
    grep -qs "matugen.css" ~/.config/gtk-$v/gtk.css || echo "@import 'matugen.css';" >> ~/.config/gtk-$v/gtk.css
done
[ -f ~/.config/gtk-3.0/settings.ini ] || cat > ~/.config/gtk-3.0/settings.ini <<EOT
[Settings]
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=breeze_cursors
gtk-cursor-theme-size=24
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=true
EOT
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
gsettings set org.gnome.desktop.interface cursor-theme breeze_cursors
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface font-name "Noto Sans 10"
# macOS-style window buttons in GTK 4 apps: close and maximize on the left (Hyprland has
# no minimize), drawn as coloured dots by window-controls.css (Matugen template)
grep -qs "window-controls.css" ~/.config/gtk-4.0/gtk.css || echo "@import 'window-controls.css';" >> ~/.config/gtk-4.0/gtk.css
gsettings set org.gnome.desktop.wm.preferences button-layout "close,maximize:"

# Nautilus like the Finder list view: list by default, small rows, folders first, name /
# size / modified columns, folders expand in place (tree view)
gsettings set org.gnome.nautilus.preferences default-folder-viewer list-view
gsettings set org.gnome.nautilus.list-view default-zoom-level small
gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'date_modified']"
gsettings set org.gnome.nautilus.list-view use-tree-view true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true

# Firefox is the default browser (links from other apps)
xdg-settings set default-web-browser firefox.desktop

# Nautilus opens folders from other apps (Firefox "Show in Folder", notifications); without
# a default the first match wins, which is kitty-open.desktop
xdg-mime default org.gnome.Nautilus.desktop inode/directory

# Services: network, Bluetooth, power modes (Fn+F8), weekly SSD trim
sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service fstrim.timer

# Docker: images and containers in their own btrfs subvolume, created before the daemon
# first starts (it creates /var/lib/docker itself otherwise). A nested subvolume is not
# part of the @ snapshots, so Timeshift does not grow with every pulled image.
if [ ! -e /var/lib/docker ] && [ "$(stat -f -c %T /var/lib)" = btrfs ]; then
    sudo btrfs subvolume create /var/lib/docker
elif [ -e /var/lib/docker ] && [ "$(sudo stat -c %i /var/lib/docker)" != 256 ]; then
    echo ":: /var/lib/docker is a plain folder, not a subvolume (see docs/plan.md, Docker)"
fi
sudo systemctl enable --now docker.service
# The docker group is root-equivalent; it applies after logging out of every session
id -nG "$USER" | grep -qw docker || sudo usermod -aG docker "$USER"

# Default folders (Pictures, Videos... used by the screenshot and recording scripts)
xdg-user-dirs-update

# Music: MPD as a user service (config dotfiles/.config/mpd) and mpd-mpris so media keys
# and Waybar control it; rmpc is the player UI. The system-wide mpd.service stays off.
mkdir -p ~/Music ~/.local/share/mpd/playlists ~/.local/state/mpd
systemctl --user enable --now mpd.service mpd-mpris.service

# zsh as the login shell (config: dotfiles/.zshrc + dotfiles/.config/zsh)
[ "$(getent passwd "$USER" | cut -d: -f7)" = /usr/bin/zsh ] || chsh -s /usr/bin/zsh

# KDE apps, if any (e.g. Dolphin): use the Matugen color scheme instead of Breeze Light
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme Matugen
fi

# VS Code: store secrets in gnome-keyring (Hyprland is not auto-detected)
echo ':: VS Code: after its first start, add "password-store": "gnome-libsecret" to ~/.vscode/argv.json'

# System files: battery thresholds (udev) and gnome-keyring unlock at login (PAM)
"$(dirname "$(realpath "$0")")/install-system-files.sh"

# Pacman hook: check the Hyprland config after every Hyprland upgrade
"$(dirname "$(realpath "$0")")/install-pacman-hooks.sh"

# First Timeshift snapshot of the finished setup (timeshift-autosnap adds one before
# every pacman upgrade from now on)
sudo timeshift --create --comments "Fresh Arch + Hyprland setup" --tags O


# ----------------------------------------------------------
# Next steps: Git, wallpapers, dotfiles (each one asks first; all can also be run later)
# ----------------------------------------------------------

SETUP_DIR=$(dirname "$(realpath "$0")")
REPO_DIR=$(dirname "$SETUP_DIR")
PERSONAL_DIR=$(dirname "$REPO_DIR")   # ~/Documents/personal: this repo, wallpapers, claude-memory
WALLPAPERS_DIR=$PERSONAL_DIR/wallpapers
ask_next() { local a; read -r -p ":: $1 [Y/n] " a; [[ ! "$a" =~ ^[Nn]$ ]]; }

echo ":: Installation complete."
echo

# Git: one or two GitHub accounts, SSH keys, aliases (setup-git.sh asks 1 or 2 itself)
if ask_next "Set up Git and the GitHub SSH keys now (setup/setup-git.sh)?"; then
    "$SETUP_DIR/setup-git.sh"
else
    echo ":: Later: $SETUP_DIR/setup-git.sh"
fi

# Wallpapers: private repo, cloned next to this one (setup/link-dotfiles.sh looks for it
# there). The GitHub account is asked, not written here, so a new username still works.
if [ -d "$WALLPAPERS_DIR/.git" ]; then
    echo ":: Wallpapers repo already at $WALLPAPERS_DIR"
elif ask_next "Clone your private wallpapers repo to $WALLPAPERS_DIR?"; then
    # Two-account setup: clone with the personal alias; one account: plain github.com
    if grep -qE '^Host[[:space:]]+github-personal([[:space:]]|$)' ~/.ssh/config 2>/dev/null; then
        host=github-personal
    else
        host=github.com
    fi
    read -r -p ":: GitHub username that owns it: " gh_user
    read -r -p ":: Repository name [wallpapers]: " gh_repo
    gh_repo=${gh_repo:-wallpapers}
    if [ -n "$gh_user" ]; then
        git clone "git@$host:$gh_user/$gh_repo.git" "$WALLPAPERS_DIR" ||
            echo ":: Clone failed; later: git clone git@$host:$gh_user/$gh_repo.git $WALLPAPERS_DIR"
    else
        echo ":: No username: skipped"
    fi
else
    echo ":: Later: git clone git@github.com:USER/wallpapers.git $WALLPAPERS_DIR"
fi

# Dotfiles: link the repo into $HOME
if ask_next "Link the dotfiles into \$HOME now (setup/link-dotfiles.sh)?"; then
    "$SETUP_DIR/link-dotfiles.sh"
else
    echo ":: Later: $SETUP_DIR/link-dotfiles.sh"
fi

# Node and Python for development: Node LTS through nvm (set as the default, so every new
# shell has node and npm) and a uv-managed Python for project venvs. The system python
# stays for Arch's own packages; never pip install into it.
PYTHON_VERSION=3.14
if ask_next "Install Node LTS (nvm) and Python $PYTHON_VERSION (uv) for development?"; then
    if [ -e /usr/share/nvm/init-nvm.sh ]; then
        # shellcheck source=/dev/null
        source /usr/share/nvm/init-nvm.sh
        nvm install --lts && nvm alias default node ||
            echo ":: Node install failed; later: nvm install --lts && nvm alias default node"
    else
        echo ":: nvm is missing (sudo pacman -S nvm); later: nvm install --lts && nvm alias default node"
    fi
    if command -v uv >/dev/null; then
        uv python install "$PYTHON_VERSION" ||
            echo ":: Python install failed; later: uv python install $PYTHON_VERSION"
    else
        echo ":: uv is missing (sudo pacman -S uv); later: uv python install $PYTHON_VERSION"
    fi
else
    echo ":: Later: nvm install --lts && nvm alias default node; uv python install $PYTHON_VERSION"
fi

# Claude Code: Anthropic's native installer (puts the launcher in ~/.local/bin/claude and
# keeps it updated). Downloaded to a file first and shown on request, never piped to bash.
if command -v claude >/dev/null || [ -x "$HOME/.local/bin/claude" ]; then
    echo ":: Claude Code already installed"
elif ask_next "Install Claude Code (official installer from claude.ai)?"; then
    installer=$(mktemp)
    if curl -fsSL -o "$installer" https://claude.ai/install.sh; then
        ask_next "Read the installer before running it?" && less "$installer"
        if ask_next "Run it now?"; then
            bash "$installer" || echo ":: Claude Code install failed; later: see docs/plan.md, Claude Code"
        fi
    else
        echo ":: Could not download the installer; later: see docs/plan.md, Claude Code"
    fi
    rm -f "$installer"
else
    echo ":: Later: see docs/plan.md, Claude Code"
fi

# Claude Code memory: a private repo with the memory of the ~/Documents/personal project and
# settings.json (layout: personal-memory/, settings.json). Needs the GitHub SSH key from the
# Git step. Claude Code keeps a project's memory under ~/.claude/projects/<path with / as ->.
MEMORY_REPO_DIR=$PERSONAL_DIR/claude-memory
MEMORY_DEST=$HOME/.claude/projects/$(printf '%s' "$PERSONAL_DIR" | tr '/' '-')/memory
if [ -d "$MEMORY_DEST" ]; then
    echo ":: Claude Code memory already at $MEMORY_DEST"
elif ask_next "Restore Claude Code memory from your private claude-memory repo?"; then
    # Default SSH host: the work alias when there are two accounts, else plain github.com
    hosts=$(awk '/^Host[[:space:]]+github-/ { print $2 }' ~/.ssh/config 2>/dev/null | tr '\n' ' ')
    default_host=github.com
    grep -qE '^Host[[:space:]]+github-work([[:space:]]|$)' ~/.ssh/config 2>/dev/null && default_host=github-work
    read -r -p ":: SSH host (${hosts:-github.com}) [$default_host]: " mem_host
    read -r -p ":: GitHub username that owns it: " mem_user
    read -r -p ":: Repository name [claude-memory]: " mem_repo
    mem_host=${mem_host:-$default_host}
    mem_repo=${mem_repo:-claude-memory}
    if [ -z "$mem_user" ]; then
        echo ":: No username: skipped"
    elif [ -d "$MEMORY_REPO_DIR/.git" ] || git clone "git@$mem_host:$mem_user/$mem_repo.git" "$MEMORY_REPO_DIR"; then
        mkdir -p "$(dirname "$MEMORY_DEST")"
        cp -r "$MEMORY_REPO_DIR/personal-memory" "$MEMORY_DEST"
        [ -f "$MEMORY_REPO_DIR/settings.json" ] && cp -f "$MEMORY_REPO_DIR/settings.json" "$HOME/.claude/settings.json"
        echo ":: Restored $(ls "$MEMORY_DEST" | wc -l) memory files to $MEMORY_DEST"
    else
        echo ":: Clone failed (is the SSH key on GitHub?); later: run this script again"
    fi
else
    echo ":: Later: run this script again, or see the claude-memory repo's README"
fi

echo
echo ":: Done. Log out and log in on TTY1: Hyprland starts and shows the wallpaper and colors."