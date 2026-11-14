# dotfiles-hyprland

Personal Hyprland setup for a ThinkPad T14 Gen 6 (AMD) on Arch Linux, with a btrfs root
encrypted by LUKS and no display manager. It started as a fork of
[ML4W Hyprland Starter](https://github.com/mylinuxforwork/hyprland-starter) 2.1 by
Stephan Raabe and has since been rewritten: the Hyprland config uses the Lua format,
colors follow the wallpaper, and the repo also installs the system pieces (snapshots,
zram, battery thresholds, keyring).

Only Arch is supported. `setup/setup-fedora.sh`, `setup/setup-opensuse.sh` and the
`.dotinst` file are left over from upstream and do not install this setup.

## Layout

| Path | Contents |
|---|---|
| `dotfiles/.config/` | One folder per app: hypr, waybar, rofi, wezterm, swaync, matugen, fcitx5, zsh, nvim, yazi, cava, fastfetch, wlogout, firefox-chrome, ml4w |
| `dotfiles/.zshrc`, `dotfiles/.zprofile` | zsh config; `.zprofile` starts Hyprland after a TTY1 login |
| `dotfiles/icons/` | Dot-matrix icons for the OSD popup |
| `bin/` | Scripts linked into `~/.local/bin` (see [Scripts](#scripts)) |
| `setup/` | Arch install scripts, system files and the pacman hook |
| `docs/plan.md` | Setup plan and notes for this machine (Vietnamese) |

## Installing Arch (boot inside the encrypted root)

archinstall: profile Minimal, **bootloader GRUB**, btrfs with the default subvolumes and
zstd compression, LUKS, EFI partition at `/boot` (default), NetworkManager, pipewire,
amd-ucode, no display manager.

When archinstall offers to chroot into the new system, say yes, install git, clone this
repo there and run `sudo setup/arch-boot-in-root.sh`. The script:

- moves the kernel and initramfs into the encrypted root and mounts the EFI partition at `/boot/efi`
- converts the LUKS key slots to PBKDF2, because GRUB cannot open Argon2 slots
- adds a keyfile to the initramfs, so the passphrase is typed once (in GRUB)
- enables `GRUB_ENABLE_CRYPTODISK`, sets a 5 s GRUB menu, reinstalls GRUB and checks the result

Reboot only when every check says ok. Like the previous Manjaro install, every Timeshift
snapshot then contains the kernel, so rollbacks and booting snapshots from the GRUB menu
(grub-btrfs) work across kernel updates. The script refuses to run on anything but Arch
or when `/boot` is not the EFI partition. It has not been tested on real hardware yet;
try it in a VM first.

## First boot

1. Log in on TTY1 (Hyprland does not start yet if the dotfiles are not linked; use TTY2
   if it does).
2. `setup/setup-arch.sh`: installs yay and all packages (official repos and AUR), then
   - enables NetworkManager, bluetooth, power-profiles-daemon, fstrim, the Lotus input server
   - sets the GTK 3/4 and Qt themes (adw-gtk3-dark, Papirus, Breeze cursor, Noto Sans), dark mode, Firefox as default browser
   - switches the login shell to zsh
   - runs `setup/install-system-files.sh` and `setup/install-pacman-hooks.sh`
   - takes the first Timeshift snapshot
3. Clone the private wallpapers repo next to this one:
   `git clone git@github-personal:diablo-harmonz/wallpapers.git ~/Documents/personal/wallpapers`
4. `setup/link-dotfiles.sh` (see below), then `wallpaper restore` to generate the colors.
5. Log out and in again on TTY1.

## Symlink install

`setup/link-dotfiles.sh` links the repo into `$HOME`, so edits in the repo apply
immediately and show up in `git status`:

- `dotfiles/.zshrc` and `dotfiles/.zprofile` to `~/`
- every folder in `dotfiles/.config/` to `~/.config/`
- `bin/*` to `~/.local/bin/`
- `dotfiles/icons/*.svg` to `~/.local/share/icons/hicolor/scalable/status/`
- `../wallpapers` to `~/Pictures/Wallpapers` (skipped if that repo is not cloned)

It then runs `bin/firefox-theme`. Existing files are moved to `*.bak-<timestamp>` first;
the script is safe to run again.

## Login

No display manager: log in on the console (TTY1) and `~/.zprofile` runs `start-hyprland`.
Quitting Hyprland (SUPER+M) returns to the login prompt; other consoles (Ctrl+Alt+F2...)
stay plain shells for repairs. Logging in on TTY2-9 while the lock screen is stuck offers
to run `lock-recover`. The keyring is unlocked through PAM (see [System files](#system-files)).

## Components

| Role | Program |
|---|---|
| Compositor | Hyprland (Lua config in `~/.config/hypr/hyprland.lua` + `conf/*.lua`) |
| Bar | Waybar |
| Launcher, menus | rofi 2.0 (Wayland) |
| Terminal | WezTerm |
| Shell | zsh with powerlevel10k, autosuggestions, syntax highlighting, history substring search |
| Notifications, OSD | swaync |
| Files | Nautilus (GUI), yazi (terminal) |
| Editor | Neovim with LazyVim (`lazy-lock.json` pins the plugins) |
| Wallpaper, colors | awww, Matugen |
| Lock, idle, night light | hyprlock, hypridle, hyprsunset |
| Logout menu | wlogout |
| Input method | fcitx5 with Lotus (Vietnamese), Bamboo as fallback |
| Clipboard | cliphist |
| Screenshots, recording | grim, slurp, satty, wf-recorder |
| Polkit, secrets | hyprpolkitagent, gnome-keyring |
| Tray apps | nm-applet, pavucontrol; blueman runs without a tray icon (pairing, notifications) |
| Bluetooth on the bar | `bin/bt-status`: devices and battery levels from UPower |
| Browser | Firefox (FF Ultima theme) |

The full package list is the `packages` array in `setup/setup-arch.sh`.

## Key bindings

Defined in `dotfiles/.config/hypr/conf/binds.lua`.

| Keys | Action |
|---|---|
| SUPER + Return | WezTerm |
| SUPER + Space | rofi app launcher (also Fn+F12) |
| SUPER + B | Browser |
| SUPER + E | Nautilus |
| SUPER + SHIFT + E | yazi in WezTerm |
| SUPER + S | Quick web search or address, opens in Firefox |
| SUPER + V | Clipboard history (Shift+Enter deletes an entry) |
| SUPER + W / SUPER + SHIFT + W | Pick a wallpaper / random wallpaper |
| SUPER + A | Audio visualizer (cava) on/off |
| SUPER + SHIFT + C | Caffeine: no idle lock or suspend |
| SUPER + L | Lock the screen |
| SUPER + CTRL + L | Black lock screen: turn the screens on and restart hyprlock (works while locked) |
| SUPER + CTRL + R | Reload the Hyprland config, restores all screens |
| SUPER + SHIFT + B | Reload Waybar |
| SUPER + Q | Close window |
| SUPER + M | Exit Hyprland |
| SUPER + T | Toggle floating |
| SUPER + F | Fullscreen (also Fn+F11) |
| SUPER + P / SUPER + J | Pseudotile / toggle split (dwindle) |
| SUPER + arrows | Move focus |
| SUPER + 1…0 | Go to workspace 1–10 |
| SUPER + SHIFT + 1…0 | Move window to workspace 1–10 |
| SUPER + mouse wheel | Next / previous workspace |
| SUPER + left / right drag | Move / resize window |
| CTRL + SHIFT + Down | Show or hide the scratchpad workspace |
| Print (Fn+F9) | Screenshot of the whole screen |
| SHIFT + Print (Fn+F10) | Screenshot of a region |
| SUPER + Print | Region screenshot, annotate in satty |
| SUPER + SHIFT + R | Start/stop recording a region |
| SUPER + ALT + R | Start/stop recording the whole screen |
| Fn+F7 | External monitor: mirror, extended, off, mirror... |
| Volume, mic, brightness keys | Change the value and show an OSD popup |
| Media keys | playerctl play/pause, next, previous, stop |

Screenshots are saved to `~/Pictures/Screenshots`, copied to the clipboard and shown in a
small preview (drag and drop, click to edit). Recordings go to `~/Videos/Recordings`.
Workspaces 1–5 stay on the laptop screen and 6–10 on the first external monitor.

On the Waybar launcher button, left click opens rofi and middle click the wallpaper picker.
The workspace pill shows a Roman numeral for an empty workspace and one app icon per
window otherwise (click an icon to focus that window); the left pill shows the app name of
the active window.

## Wallpaper and colors

`SUPER+W` opens a wallpaper picker (`bin/wallpaper`, rofi with thumbnails), `SUPER+SHIFT+W`
picks one at random. Wallpapers come from `~/Pictures/Wallpapers`; this repo ships none
(they are third-party art, kept in a private repo).

After each change Matugen (`dotfiles/.config/matugen`) generates matching colors for
rofi, Waybar, WezTerm, the Hyprland borders, GTK 3, GTK 4, swaync, Qt (qt6ct), KDE apps,
Firefox, yazi and cava. The generated files are git-ignored; run `wallpaper restore` once
after linking (Hyprland also runs it at login).

## Firefox

`dotfiles/.config/firefox-chrome` holds the FF Ultima theme (CSS only, commit 73129fa,
MPL 2.0) recolored from the wallpaper by Matugen, plus a `user.js` with vertical tabs and
the toolbar, tab sidebar and bookmarks bar hidden until the pointer reaches an edge.
`setup/link-dotfiles.sh` links it into the default profile through `bin/firefox-theme`
(on a fresh system it starts Firefox headless once so the profile exists). Its devtools
remote-debugging prefs are deliberately not included. Extensions are installed by the
Firefox policy (see below).

## System files

`setup/install-system-files.sh` (run by `setup-arch.sh`, needs sudo, safe to run again)
installs from `setup/system/`:

- **Battery charge thresholds 75/80**: a oneshot service sets them at boot. The Waybar
  leaf/bolt button (`bin/battery-mode`) switches between 75–80 % and a full 100 % charge
  through a root-owned helper and a polkit action (password each time). A reboot always
  returns to 75–80 %.
- **gnome-keyring via PAM**: unlocked with the login password (sddm, greetd or console
  login) and kept in sync when the password changes.
- **zram**: size = RAM, zstd, plus the vm sysctls for zram (`99-vm-zram.conf`). A new
  size applies at the next boot.
- **earlyoom**: stops the biggest process (test browsers first) before memory runs out;
  avoids the desktop, terminal, editor, lock screen, audio and input method.
- **Firefox policy**: installs uBlock Origin, Proton Pass and Unhook from addons.mozilla.org.
- **Bluetooth**: bluetoothd runs without its GATT battery plugin, so headsets that report
  0 % over GATT but the real level over HFP (Marshall Major V) show the HFP level,
  forwarded by PipeWire. Logitech devices report through the kernel HID++ driver.
- **Timeshift** (btrfs): daily 5, weekly 3, `/home` excluded; grub-btrfsd keeps the GRUB
  snapshot menu up to date, cronie runs the schedule. timeshift-autosnap takes a
  snapshot before every pacman upgrade.

## Pacman hook

`setup/install-pacman-hooks.sh` (run by `setup/setup-arch.sh`, needs sudo) installs a hook that runs `Hyprland --verify-config` on every user's Hyprland config after each Hyprland install or upgrade, so a breaking change shows up in the pacman output instead of as a black screen at the next login. The hook script is copied root-owned to `/usr/local/lib/dotfiles-hyprland/`, because a root hook must never execute a file inside `$HOME`. Run the script again after editing `setup/pacman-hooks/`. To check by hand: `setup/pacman-hooks/hyprland-verify-config`.

## Scripts

| Script | Purpose |
|---|---|
| `wallpaper` | Pick, set and theme from the wallpaper (`select`, `random`, `restore`) |
| `screenshot`, `screenshot-preview` | Screenshots with file, clipboard and preview |
| `screenrec` | Start/stop screen recording |
| `clipboard` | Clipboard history picker |
| `web-search` | Quick search / address bar |
| `caffeine` | Keep the laptop awake, also handles the lid while on |
| `display-toggle` | External monitor cycle (Fn+F7) |
| `dpms` | Turn the screens on or off only when needed |
| `lock-recover` | Fix a black or dead lock screen, the session stays locked |
| `osd` | Volume, mic and brightness with a popup |
| `battery-mode` | Charge limit 75–80 % or 100 % |
| `powermode-notify` | Notification when the power profile changes (Fn+F8) |
| `media-status` | Waybar media module |
| `bt-status` | Waybar Bluetooth module: icon on the bar, connected devices and their batteries in the tooltip |
| `sysinfo-bar`, `sysmetrics`, `syslive` | CPU/RAM on Waybar, metrics, live status view |
| `sysreport` | One-shot machine health report |
| `cava-toggle` | Floating audio visualizer |
| `firefox-theme` | Link the Firefox theme into the default profile |

## Checking the config

```
Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

Monitor changes can be tried without a cable: `hyprctl output create headless`.
From a TTY, name the instance: `hyprctl -i 0 reload`.

## License

GPL-3.0, like the upstream ML4W Hyprland Starter. The FF Ultima files in
`dotfiles/.config/firefox-chrome` are MPL 2.0.
