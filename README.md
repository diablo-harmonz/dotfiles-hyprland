# ML4W Hyprland Starter 2.1


The ML4W Hyprland Starter package is the perfect starting point for your Hyprland customization experiments. The Hyprland Starter configuration works on all Linux distributions that support the dynamic tiling window manager Hyprland.

![hyprland-starter20](https://github.com/user-attachments/assets/71e387ff-68a6-4c4d-a98c-6d6a86fb900e)

You can find the configuration here: https://github.com/mylinuxforwork/hyprland-starter/tree/main/dotfiles

## Installation

You can install the ML4W Hyprland Starter easily with the Dotfiles Installer from an existing Window Manager or Desktop Environment.

<a href="https://mylinuxforwork.github.io/dotfiles-installer/" target="_blank"><img src="https://mylinuxforwork.github.io/dotfiles-installer/dotfiles-installer-badge.png" style="border:0;margin-bottom:10px"></a>

More information about the installation of the Dotfiles Installer here: https://github.com/mylinuxforwork/dotfiles-installer/wiki/01-Installation

Copy the following url into the Dotfiles Installer.

```
https://raw.githubusercontent.com/mylinuxforwork/hyprland-starter/main/hyprland-starter.dotinst
```
Please run the setup script offered by the Dotfiles Installer to install all dependencies. If your distribution is not supported, please install the following dependencies manually:

- hyprland
- waybar
- rofi (2.0+, includes Wayland support)
- wezterm
- swaync (notifications)
- pavucontrol, network-manager-applet, blueman, bluez
- nautilus, nautilus-open-any-terminal
- xdg-desktop-portal-hyprland
- qt5-wayland
- qt6-wayland
- awww (wallpaper), matugen (colors from the wallpaper), imagemagick (thumbnails)
- hyprlock
- hypridle
- hyprsunset
- firefox
- woff2-font-awesome, noto-fonts, noto-fonts-emoji
- vim
- fastfetch
- ttf-fira-sans
- ttf-fira-code
- ttf-firacode-nerd
- jq
- brightnessctl
- networkmanager
- wireplumber
- fcitx5, fcitx5-gtk, fcitx5-qt, fcitx5-configtool
- fcitx5-lotus (AUR; then `sudo systemctl enable --now fcitx5-lotus-server@$USER.service`)
- fcitx5-bamboo (fallback input method)

> Hyprland does not officially support NVIDIA hardware. But many users have reported a successful installation. Please read: https://wiki.hyprland.org/Nvidia/

## Symlink install (this fork)

To use the configs straight from this repository (edits apply immediately), clone it and run:

```
setup/link-dotfiles.sh
```

It links `dotfiles/.zshrc`, every folder in `dotfiles/.config/` and the scripts in `bin/` into `$HOME`. Existing files are moved to `*.bak-<timestamp>` first. The Hyprland config uses the Lua format (`~/.config/hypr/hyprland.lua`).

## Login

No display manager: log in on the console (TTY1) and `~/.zprofile` runs `start-hyprland`.
Quitting Hyprland returns to the login prompt; other consoles (Ctrl+Alt+F2...) stay plain
shells. The keyring is unlocked through `/etc/pam.d/login` (see below).

## System files

`setup/install-system-files.sh` (run by `setup-arch.sh`, needs sudo) installs the battery
charge thresholds (75/80, udev rule in `setup/system/`) and adds `pam_gnome_keyring` to the
login PAM file (sddm, greetd or console login) so the keyring unlocks with the login password.

## Wallpaper and colors

`SUPER+W` opens a wallpaper picker (`bin/wallpaper`, rofi with thumbnails), `SUPER+SHIFT+W`
picks one at random. Wallpapers come from `~/Pictures/Wallpapers` and `~/.config/ml4w/wallpapers`.
After each change Matugen (`dotfiles/.config/matugen`) generates matching colors for rofi,
waybar, WezTerm, GTK 4 and the Hyprland borders. Those generated files are git-ignored; run
`wallpaper restore` once after linking (Hyprland also runs it at login).

### Pacman hook

`setup/install-pacman-hooks.sh` (run by `setup/setup-arch.sh`, needs sudo) installs a hook that runs `Hyprland --verify-config` on every user's Hyprland config after each Hyprland install or upgrade, so a breaking change shows up in the pacman output instead of as a black screen at the next login. The hook script is copied root-owned to `/usr/local/lib/dotfiles-hyprland/`, because a root hook must never execute a file inside `$HOME`. Run the script again after editing `setup/pacman-hooks/`. To check by hand: `setup/pacman-hooks/hyprland-verify-config`.

## Documentation (Wiki)

You can find the complete documentation of the ML4W Starter in the Wiki. <b>[Open the Wiki here](https://github.com/mylinuxforwork/hyprland-starter/wiki)</b>

## Dependencies

The script will install the following packages and the corresponding configurations:

- Window Manager: hyprland 
- Status Bar: waybar 
- Launcher: rofi
- Browser: Firefox
- Terminal: wezterm
- Notification Service: dunst 
- File Manager: Thunar
- xdg-desktop-portal-hyprland 
- qt5-wayland 
- qt6-wayland 
- Lock screen: hyprlock

## Key Bindings

The following custom key bindings are enabled (can be customized in ~/.config/hypr/conf/binds.lua)

- <kbd>SUPER</kbd> + <kbd>RETURN</kbd> to start terminal
- <kbd>SUPER</kbd> + <kbd>Q</kbd> to quit an application
- <kbd>SUPER</kbd> + <kbd>B</kbd> to start browser
- <kbd>SUPER</kbd> + <kbd>M</kbd> to exit Hyprland
- <kbd>SUPER</kbd> + <kbd>E</kbd> to start filemanager
- <kbd>SUPER</kbd></kbd> + <kbd>CTRL</kbd> + <kbd>RETURN</kbd> to start launcher rofi
- <kbd>SUPER</kbd> + <kbd>T</kbd> to toggle floating
- <kbd>SUPER</kbd> + <kbd>F</kbd> to toggle fullscreen
- <kbd>SUPER</kbd> + <kbd>1-9</kbd> to switch workspaces
- more key bindings in ~/.config/hypr/conf/binds.lua

or after the installation with right mouse click on Apps in the status bar.
