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
    "wezterm"
    "swaync"
    "hyprpolkitagent"
    "qt6ct"
    "cliphist"
    "python-gobject"
    "gtk4-layer-shell"
    "pavucontrol"
    "network-manager-applet"
    "blueman"
    "bluez"
    "bluez-utils"
    "nautilus"
    "nautilus-open-any-terminal"
    "xdg-desktop-portal-hyprland"
    "qt5-wayland"
    "qt6-wayland"
    "awww"
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
    "resvg"
    "tree-sitter-cli"
    "ripgrep"
    "poppler"
    "7zip"
    "btop"
    "htop"
    "zram-generator"
    "earlyoom"
    "timeshift"
    "timeshift-autosnap"
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
    "wlogout"
    "fcitx5"
    "fcitx5-gtk"
    "fcitx5-qt"
    "fcitx5-configtool"
    "fcitx5-lotus"
    "fcitx5-bamboo"
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

# Nautilus: "Open in Terminal" opens WezTerm
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal wezterm
# Blueman: monochrome icons; no tray icon (Waybar's bluetooth module replaces it, the
# applet keeps running for pairing and notifications)
gsettings set org.blueman.general symbolic-status-icons true
gsettings set org.blueman.general plugin-list "['!StatusNotifierItem']"

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

# GTK: dark adw-gtk3 theme for GTK 3 apps (pavucontrol, blueman...), Matugen colors
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

# Firefox is the default browser (links from other apps)
xdg-settings set default-web-browser firefox.desktop

# Services: network, Bluetooth, power modes (Fn+F8), weekly SSD trim
sudo systemctl enable --now NetworkManager.service bluetooth.service power-profiles-daemon.service fstrim.timer

# Default folders (Pictures, Videos... used by the screenshot and recording scripts)
xdg-user-dirs-update

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
# Completed
# ----------------------------------------------------------

echo ":: Installation complete."
echo ":: Ready to install the dotfiles with the Dotfiles Installer."