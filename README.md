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
| `dotfiles/.config/` | One folder per app: hypr, waybar, rofi, kitty, swaync, matugen, fcitx5, zsh, nvim, yazi, cava, fastfetch, wlogout, firefox-chrome, ml4w |
| `dotfiles/.zshrc`, `dotfiles/.zprofile` | zsh config; `.zprofile` starts Hyprland after a TTY1 login |
| `dotfiles/icons/` | Dot-matrix icons for the OSD popup |
| `bin/` | Scripts linked into `~/.local/bin` (see [Scripts](#scripts)) |
| `setup/` | Arch install scripts, system files and the pacman hook |
| `docs/plan.md` | Setup plan and notes for this machine (Vietnamese) |
| `docs/sleep.md` | Lid close and suspend: unplug the mouse receiver, finding what wakes the laptop (Vietnamese) |

## Installing Arch (boot inside the encrypted root)

archinstall: profile Minimal, **bootloader GRUB with Unified kernel images and Removable both Disabled** (newer archinstall turns them on by default; `arch-boot-in-root.sh` needs a plain kernel + initramfs), btrfs with the default subvolumes and
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
   - then offers steps 3 to 5 one by one (Enter = yes, n = later), so a fresh install is
     one command; each script can also be run on its own later
3. `setup/setup-git.sh`: guided Git setup. It first asks for one GitHub account or two:
   - one: plain Git, the identity in `~/.gitconfig`, the key `~/.ssh/id_ed25519`; clone
     anywhere with `git clone git@github.com:USER/REPO.git`
   - two (personal + work): one identity per folder (`~/Documents/personal`,
     `~/Documents/work`, `~/.gitconfig-<profile>` with `includeIf`), a key and a
     `github-<profile>` alias per account; clone with `git@github-<profile>:USER/REPO.git`

   Then it shows the public key to paste on GitHub and tests the connection. Names, emails
   and usernames are typed in, nothing is stored in the script. It asks before every
   change; `setup/setup-git.sh check` only reports.
4. Clone your private wallpapers repo next to this one (setup-arch.sh asks for the GitHub
   username): `git clone git@github.com:USER/wallpapers.git ~/Documents/personal/wallpapers`
   (with two accounts: `git@github-personal:USER/...`)
5. `setup/link-dotfiles.sh` (see below), then `wallpaper restore` to generate the colors.
6. Log out and in again on TTY1.

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
| Bar | Waybar, minimal like macOS: launcher, app name, CPU / RAM, workspaces (Roman numerals), tray, Wi-Fi, battery, the Control Center icon, notification bell (right click: Do Not Disturb), clock (click: notifications), timer countdown while one runs, power button |
| Launcher, menus | rofi 2.0 (Wayland) |
| Terminal | kitty (its image protocol keeps transparency for pictures in terminal apps) |
| Shell | zsh with powerlevel10k, autosuggestions, syntax highlighting, history substring search |
| Notifications, OSD | swaync: compact translucent cards, control center with a media player card; OSD popups for volume and brightness |
| Files | Nautilus (GUI), yazi (terminal) |
| Editor | Neovim with an own config built stage by stage (`dotfiles/.config/nvim`, roadmap `docs/neovim.md`); VS Code as the fallback |
| Claude Code | Status line: folder, git branch, model, context bar, 5-hour / 7-day plan usage (`dotfiles/.claude/statusline.sh`; `setup/link-dotfiles.sh` adds the `statusLine` entry to `~/.claude/settings.json`) |
| Wallpaper, colors | awww, Matugen |
| Lock, idle, night light | hyprlock, hypridle, hyprsunset |
| Power menu | wlogout via `bin/power-menu`: Lock, Shutdown, Suspend, Reboot, Logout, BIOS over the blurred desktop |
| Input method | fcitx5 with Lotus (Vietnamese, Telex; a lone `w` types ư everywhere, `ww` types w), Bamboo as fallback |
| Clipboard | cliphist |
| Screenshots, recording | grim, slurp, satty, wf-recorder |
| Polkit, secrets | hyprpolkitagent, gnome-keyring |
| Audio, Bluetooth, Wi-Fi | wiremix, bluetui and nmtui in floating kitty windows (`bin/tui-popup`), opened from the Waybar volume, Bluetooth and Wi-Fi icons |
| Bluetooth on the bar | `bin/bt-status`: devices and battery levels from UPower |
| Browser | Firefox (FF Ultima theme) |
| Media | mpv (video, also for yt-x; resumes where you left off, but a video played to the end starts over), yt-dlp (downloads to `~/Videos/YouTube`), yt-x (YouTube in the terminal; videos open as a small window in the bottom-right corner, pinned to every workspace), MPD + rmpc (music in `~/Music`; player view with the record picture, queue and library as icon tabs, a keys tab); media keys and Waybar control mpv and MPD through MPRIS |

The full package list is the `packages` array in `setup/setup-arch.sh`.

## Key bindings

Defined in `dotfiles/.config/hypr/conf/binds.lua`.

| Keys | Action |
|---|---|
| SUPER + Return | kitty |
| SUPER + Space | rofi app launcher (also Fn+F12) |
| SUPER + B | Browser |
| SUPER + E | Nautilus |
| SUPER + SHIFT + E | yazi in kitty |
| SUPER + S | Quick web search or address, opens in Firefox |
| SUPER + V | Clipboard history (Shift+Enter deletes an entry) |
| SUPER + = | Calculator (rofi-calc, also units and currencies): Enter copies the result |
| SUPER + SHIFT + T | Timer or alarm: `10m tea`, `1h30m`, `07:30 wake up`; countdown on Waybar, pick one to cancel |
| SUPER + W / SUPER + SHIFT + W | Pick a wallpaper / random wallpaper |
| SUPER + A | Audio visualizer (cava) on/off |
| SUPER + SHIFT + C | Caffeine: no idle lock or suspend |
| SUPER + L | Lock the screen |
| SUPER + CTRL + L | Black lock screen: turn the screens on and restart hyprlock (works while locked) |
| SUPER + CTRL + Escape | Way out of a virtual machine or remote desktop that holds the keyboard: leaves fullscreen, back to the previous workspace (always reaches Hyprland) |
| SUPER + CTRL + R | Reload the Hyprland config, restores all screens |
| SUPER + SHIFT + B | Reload Waybar |
| SUPER + Q | Close window |
| SUPER + M | Exit Hyprland |
| SUPER + T | Toggle floating |
| SUPER + O | Pin a floating window to every workspace (picture-in-picture), press again to unpin |
| SUPER + F | Fullscreen (also Fn+F11) |
| SUPER + P / SUPER + J | Pseudotile / toggle split (dwindle) |
| SUPER + arrows | Move focus; two arrows together (e.g. up + right) focus the floating window in that screen corner |
| SUPER + SHIFT + arrows | Move the window: floating glides while held, speeding up (two arrows: diagonal), tiled swaps with the neighbour |
| SUPER + ALT + arrows | Resize the window (hold to repeat) |
| SUPER + 1…0 | Go to workspace 1–10 |
| SUPER + SHIFT + 1…0 | Move window to workspace 1–10 |
| SUPER + CTRL + ← / → | Previous / next workspace in number order (this monitor, empty ones too) |
| SUPER + CTRL + SHIFT + ← / → | Take the window to the previous / next workspace and follow it |
| SUPER + mouse wheel | Next / previous workspace |
| SUPER + left / right drag | Move / resize window |
| CTRL + SHIFT + Down | Show or hide the scratchpad workspace |
| Print (Fn+F9) | Screenshot of the whole screen |
| SHIFT + Print (Fn+F10) | Screenshot of a region |
| SUPER + Print | Region screenshot, annotate in satty |
| SUPER + SHIFT + R | Start/stop recording a region |
| SUPER + ALT + R | Start/stop recording the whole screen |
| SUPER + CTRL + 3 | Screenshot of the whole screen (like macOS ⌘⇧3) |
| SUPER + CTRL + 4 | Screenshot toolbar: selection, window, entire screen, annotate, in 5 seconds |
| SUPER + CTRL + 5 | Recording toolbar: selection, window or entire screen, with or without sound; stop |
| Fn+F7 | External monitor: mirror, extended, off, mirror... |
| Volume, mic, brightness keys | Change the value and show an OSD popup |
| Media keys | playerctl play/pause, next, previous, stop on the most recently active player (playerctld) |

Screenshots are saved to `~/Pictures/Screenshots`, copied to the clipboard and shown in a
small preview (drag and drop, click to edit). Recordings go to `~/Videos/Recordings`;
while recording, Waybar shows a red stop button with the elapsed time, and when it stops
the same preview shows the video (drag it into an app, click to play, copy or delete it).
Workspaces 1–5 stay on the laptop screen and 6–10 on the first external monitor.

On the Waybar launcher button, left click opens rofi and middle click the wallpaper picker.
The workspace pill shows Roman numerals; the left pill shows the app name of the active
window and, next to it, CPU and RAM use.

## Wallpaper and colors

`SUPER+W` opens a wallpaper picker (`bin/wallpaper`, rofi with thumbnails), `SUPER+SHIFT+W`
picks one at random. Wallpapers come from `~/Pictures/Wallpapers`; this repo ships none
(they are third-party art, kept in a private repo).
The fastfetch logo works the same way: put a picture named `logo.*` in `fastfetch/` of
that repo (linked to `~/Pictures/fastfetch`) and fastfetch shows it in kitty instead of the
distro logo; without one it keeps the small distro logo.

After each change Matugen (`dotfiles/.config/matugen`) generates matching colors for
rofi, Waybar, kitty, the Control Center, the Hyprland borders, hyprlock, wlogout, GTK 3, GTK 4, swaync, Qt (qt6ct), KDE apps,
Firefox, yazi, cava, btop, rmpc, yt-x, navi and the zsh command colors (syntax highlighting). The generated files are git-ignored; run `wallpaper restore` once
after linking (Hyprland also runs it at login). The colors are made after the 1.2 s wallpaper
transition so it stays smooth. Waybar picks up its new colors by itself
(`reload_style_on_change`); it is never sent SIGUSR2, which crashed Waybar 0.15.

Translucent apps: list them in `translucent` at the top of
`dotfiles/.config/hypr/conf/windowrules.lua` (class, opacity focused / unfocused; Telegram
is there). It fades the whole window, text included; kitty fades only its background with
its own `background_opacity`. To find an app's class: navi (Ctrl+G), "window class".

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
- **Firewall** (nftables, `setup/system/nftables.conf`): nothing from the network may
  connect in, replies to the laptop's own connections pass. Ports published by Docker
  are reachable from this laptop only (a forward rule drops new connections from the
  network to containers); containers and libvirt VMs still reach the host and the
  internet.
- **faillock**: 5 wrong passwords (lock screen, sudo, login) within 15 minutes lock
  the account for 2 minutes instead of 3 for 10 minutes. hyprlock also ignores Enter on
  an empty field, so the key that wakes the laptop is not a failed attempt.
- **Bluetooth**: bluetoothd runs without its GATT battery plugin, so headsets that report
  0 % over GATT but the real level over HFP (Marshall Major V) show the HFP level,
  forwarded by PipeWire. Logitech devices report through the kernel HID++ driver.
- **Timeshift** (btrfs): daily 5, weekly 3, `/home` excluded; grub-btrfsd keeps the GRUB
  snapshot menu up to date, cronie runs the schedule. timeshift-autosnap takes a
  snapshot before every pacman upgrade.

## Pacman hook

`setup/install-pacman-hooks.sh` (run by `setup/setup-arch.sh`, needs sudo) installs a hook that runs `Hyprland --verify-config` on every user's Hyprland config after each Hyprland install or upgrade, so a breaking change shows up in the pacman output instead of as a black screen at the next login. The hook script is copied root-owned to `/usr/local/lib/dotfiles-hyprland/`, because a root hook must never execute a file inside `$HOME`. Run the script again after editing `setup/pacman-hooks/`. To check by hand: `setup/pacman-hooks/hyprland-verify-config`. A second hook does the same for rmpc: after an rmpc upgrade it starts rmpc for two seconds with each user's config and theme and prints rmpc's error if it cannot read them (`setup/pacman-hooks/rmpc-verify-config`, also by hand). A third one renders the Matugen templates into a temporary folder after a Matugen upgrade (real colour files untouched, no post hooks) and names the template and line of every error or left-over `{{...}}` (`setup/pacman-hooks/matugen-verify-config`).

## Scripts

| Script | Purpose |
|---|---|
| `wallpaper` | Pick, set and theme from the wallpaper (`select`, `random`, `restore`) |
| `screenshot`, `screenshot-preview` | Screenshots with file, clipboard and preview |
| `screenrec` | Start/stop screen recording |
| `capture-menu` | macOS-style screenshot / recording toolbar (rofi) |
| `control-center` | macOS-style Control Center from the Waybar icon: Wi-Fi, Bluetooth, Do Not Disturb, Caffeine, now playing, brightness and volume sliders, charge limit, power mode, record, screenshot, wallpaper, lock, notifications, power menu; x on the player stops it |
| `tui-popup` | Toggle wiremix / bluetui / nmtui as a floating terminal under the bar |
| `power-menu` | wlogout grid centred on the focused screen (Waybar power button) |
| `yt-music` | Download songs as best-quality audio into ~/Music/<artist>/<title>/ and make their record picture |
| `vinyl-cover` | Record picture for rmpc: square sleeve with a vinyl pulled half out (cover.png per folder) |
| `rmpc-notify` | rmpc song-change notification with the album art |
| `sysupdate` | Guided weekly update (see Updating) |
| `navi` (Ctrl+G in zsh) | Command notebook: every command of this setup with a description, searchable; add your own in `dotfiles/.config/navi/cheats/dotfiles.cheat`. `tldr <command>` (tealdeer) for common commands |
| `rec-status` | Waybar red stop button with the elapsed time while recording |
| `clipboard` | Clipboard history picker |
| `web-search` | Quick search / address bar |
| `caffeine` | Keep the laptop awake, also handles the lid while on |
| `calc` | Calculator under the bar (rofi-calc): units, currencies, percentages; Enter copies the result |
| `timer` | Countdown timers and alarms as systemd user timers (ring after sleep too), Waybar countdown, snooze from the notification |
| `display-toggle` | External monitor cycle (Fn+F7); closing the lid with a monitor plugged in leaves only the external screen, opening it restores the extended layout |
| `dpms` | Turn the screens on or off only when needed |
| `lock-recover` | Fix a black or dead lock screen, the session stays locked |
| `osd` | Volume, mic and brightness with a popup |
| `battery-mode` | Charge limit 75–80 % or 100 % |
| `powermode-notify` | Notification when the power profile changes (Fn+F8) |
| `media-clear` | Stop every player (swaync panel: MEDIA … CLEAR): mpv quits, Firefox and mpd stop, orphaned mpv is ended |
| `media-status` | Waybar play/pause button for the active player (playerctld): left click play/pause, right click pause every player, middle click next player |
| `bt-status` | Waybar Bluetooth module: icon on the bar, connected devices and their batteries in the tooltip |
| `sysinfo-bar`, `sysmetrics`, `syslive` | CPU/RAM on Waybar, metrics, live status view |
| `sysreport` | One-shot machine health report |
| `cava-toggle` | Floating audio visualizer |
| `firefox-theme` | Link the Firefox theme into the default profile |

## Updating

Run `sysupdate` (`bin/sysupdate`): Arch news, the packages that will change (kernel and Hyprland releases flagged), a power check, an optional manual Timeshift snapshot, `yay -Syu` recorded to `~/.local/state/sysupdate/`, then a summary of hook warnings, `.pacnew` files and whether to reboot. Step-by-step guide (Vietnamese): `docs/update.md`.

## Checking the config

```
Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

Monitor changes can be tried without a cable: `hyprctl output create headless`.
From a TTY, name the instance: `hyprctl -i 0 reload`.

## License

GPL-3.0, like the upstream ML4W Hyprland Starter. The FF Ultima files in
`dotfiles/.config/firefox-chrome` are MPL 2.0.
