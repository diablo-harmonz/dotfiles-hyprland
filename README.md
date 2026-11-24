# dotfiles-hyprland

Personal Hyprland setup for a ThinkPad T14 Gen 6 (AMD) on Arch Linux, with a btrfs root
encrypted by LUKS and no display manager. It started as a fork of
[ML4W Hyprland Starter](https://github.com/mylinuxforwork/hyprland-starter) 2.1 by
Stephan Raabe and has since been rewritten: the Hyprland config uses the Lua format,
colors follow the wallpaper, every corner, border and font comes from one design-token
file per theme, and the repo also installs the system pieces (snapshots, zram, battery
thresholds, keyring, hibernate, pacman hooks).

Only Arch is supported. `setup/setup-fedora.sh`, `setup/setup-opensuse.sh` and the
`.dotinst` file are left over from upstream and do not install this setup.

This README is meant to be enough to understand and change everything by hand. Start with
[How it fits together](#how-it-fits-together), then [How do I…](#how-do-i) for recipes and
[When something breaks](#when-something-breaks) for repairs.

**Contents**

1. [Repository map](#repository-map)
2. [Installing Arch](#installing-arch-boot-inside-the-encrypted-root) · [First boot](#first-boot) · [Symlink install](#symlink-install) · [Login](#login)
3. [How it fits together](#how-it-fits-together)
4. [Look: wallpaper, colors, theme packs, design tokens](#look-wallpaper-colors-theme-packs-design-tokens)
5. [Components](#components) and the [desktop panels in detail](#desktop-panels-in-detail)
6. [Key bindings](#key-bindings)
7. [Sleep, lid and hibernate](#sleep-lid-and-hibernate)
8. [System files](#system-files) · [Pacman hooks and dotfiles-verify](#pacman-hooks-and-dotfiles-verify)
9. [Scripts](#scripts)
10. [How do I…](#how-do-i)
11. [When something breaks](#when-something-breaks)
12. [Updating](#updating) · [License](#license)

---

## Repository map

| Path | Contents |
|---|---|
| `dotfiles/.config/<app>/` | One folder per app, each linked whole to `~/.config/<app>`: btop, cava, control-center, fastfetch, fcitx5, firefox-chrome, hypr, kitty, matugen, ml4w (two small helper scripts kept from upstream), mpd, mpv, navi, nvim, pacman, quickshell, rmpc, rofi, swaync, waybar, yazi, yt-dlp, yt-x, zsh |
| `dotfiles/.zshrc`, `dotfiles/.zprofile` | zsh config; `.zprofile` starts Hyprland after a TTY1 login |
| `dotfiles/icons/` | Dot-matrix icons of the volume / brightness / mic popup (`bin/osd`) |
| `dotfiles/applications/` | Desktop entries for terminal apps (rmpc, yt-x) |
| `bin/` | Scripts, each linked to `~/.local/bin/` (see [Scripts](#scripts)) |
| `themes/<pack>/` | Theme packs: `default` and `cosmos` (see [Theme packs](#theme-packs)) |
| `setup/` | Arch install scripts, `setup/system/` (files installed as root), `setup/pacman-hooks/` |
| `docs/plan.md` | Setup plan and notes for this machine (Vietnamese) |
| `docs/sleep.md` | Lid close, suspend, hibernate; finding what wakes the laptop (Vietnamese) |
| `docs/update.md` | Step-by-step guide to `sysupdate` (Vietnamese) |
| `docs/neovim.md` | Roadmap of the Neovim config |

Files that are **generated** and therefore git-ignored or outside the repo (never edit them,
edit their source and regenerate):

| Generated file | Made by | From |
|---|---|---|
| `~/.config/*/colors.*`, `~/.config/gtk-*/matugen.css`, … | Matugen (`bin/wallpaper`, `bin/colors`) | `dotfiles/.config/matugen/templates/*` |
| `~/.config/theme-tokens/*` | `bin/tokens` | `themes/default/tokens.conf` + the active pack's `tokens.conf` |
| `$XDG_RUNTIME_DIR/waybar/config.json`, `style.css` | `bin/waybar-launch` | `waybar/config`, `waybar/style.in.css`, the theme pack, the tokens |
| `~/.config/theme` (a link) | `bin/theme apply` | `themes/<pack>` |
| `~/.cache/wallpaper/current` (a link) | `bin/wallpaper` | the chosen wallpaper |

---

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

Reboot only when every check says ok. Every Timeshift snapshot then contains the kernel, so
rollbacks and booting snapshots from the GRUB menu (grub-btrfs) work across kernel updates.
The script refuses to run on anything but Arch or when `/boot` is not the EFI partition.

## First boot

1. Log in on TTY1 (Hyprland does not start yet if the dotfiles are not linked; use TTY2
   if it does).
2. `setup/setup-arch.sh`: installs yay and all packages (official repos and AUR), then
   - enables NetworkManager, bluetooth, power-profiles-daemon, fstrim, the Lotus input server
   - sets the GTK 3/4 and Qt themes (adw-gtk3-dark, Papirus, Breeze cursor, Noto Sans), dark
     mode, no window buttons in GTK header bars (Hyprland closes and maximizes windows),
     Firefox as default browser
   - switches the login shell to zsh
   - runs `setup/install-system-files.sh` and `setup/install-pacman-hooks.sh`
   - takes the first Timeshift snapshot
   - asks to enable hibernate (`setup/enable-hibernate.sh`, see
     [Sleep, lid and hibernate](#sleep-lid-and-hibernate); skipped in a VM, live after a reboot)
   - then offers steps 3 to 5 one by one (Enter = yes, n = later), so a fresh install is
     one command; each script can also be run on its own later
   - last, offers Claude Code (the official installer, downloaded to a file and shown on
     request before it runs) and restoring its memory from a private `claude-memory` repo
     (`personal-memory/` and `settings.json`, cloned next to this repo)
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
- `dotfiles/applications/*.desktop` to `~/.local/share/applications/`
- `themes/default` to `~/.config/theme` (only when no theme pack is active yet)
- `../wallpapers` to `~/Pictures/Wallpapers` (skipped if that repo is not cloned)

It then writes the design tokens (`bin/tokens`) and runs `bin/firefox-theme`. Existing
files are moved to `*.bak-<timestamp>` first; the script is safe to run again. A new file
in `bin/` needs one more run of this script (or `ln -s` by hand) to appear in `~/.local/bin`.

## Login

No display manager: log in on the console (TTY1) and `~/.zprofile` runs `start-hyprland`.
Quitting Hyprland (SUPER+M) returns to the login prompt; other consoles (Ctrl+Alt+F2...)
stay plain shells for repairs. Logging in on TTY2-9 while the lock screen is stuck offers
to run `lock-recover`. The keyring is unlocked through PAM (see [System files](#system-files)).

---

## How it fits together

```
                     ┌───────────── themes/<pack>/ ─────────────┐
                     │ tokens.conf  hyprland.lua  hyprlock.conf │
 bin/theme apply ──► │ waybar.json  waybar.css   rofi.rasi  ... │ ──► ~/.config/theme (link)
                     └──────────────────────────────────────────┘
                                         │
 themes/default/tokens.conf ─┐           ▼
 + pack tokens.conf ─────────┴──► bin/tokens ──► ~/.config/theme-tokens/
                                    tokens.rasi (rofi)  tokens.css (GTK 4)  tokens.json (Quickshell)
                                    tokens.lua (Hyprland)  tokens.conf (hyprlock)  kitty.conf
                                    tokens.env (waybar-launch fills style.in.css)

 wallpaper ──► bin/wallpaper ──► bin/colors ──► Matugen ──► colors for every app
                                  (source: wallpaper color N,   (templates in
                                   a preset or #rrggbb, scheme)  dotfiles/.config/matugen)
```

Three independent layers decide how something looks:

1. **Colors** come from the wallpaper (or a fixed color) through Matugen. Every app reads a
   generated color file; nothing has a hard-coded palette (a few fixed colors stay on
   purpose: the red recording button, the black backdrop).
2. **Shapes and fonts** (corner radii, border width, font families, backdrop dim, panel
   opacity, panel style) come from the design tokens. No config should contain its own
   radius or font family; [the check](#check-that-nothing-is-hard-coded) finds the ones
   that do.
3. **Theme pack extras**: things a pack changes beyond tokens (wallpaper, Hyprland borders
   and animations, the lock screen layout, Waybar icons, fastfetch).

Panels that are opened rarely (Settings, the wallpaper picker, menus) start on demand and
quit when closed: nothing of them runs in the background.

---

## Look: wallpaper, colors, theme packs, design tokens

### Wallpaper and colors

`SUPER+W` opens the wallpaper picker (`bin/wallpaper select`: a Quickshell carousel,
`~/.config/quickshell/wallpicker`; the rofi thumbnail row `wallpaper select-rofi` is the
fallback), `SUPER+SHIFT+W` picks one at random. Wallpapers come from `~/Pictures/Wallpapers`;
this repo ships none (they are third-party art, kept in a private repo). The fastfetch
logo works the same way: put a picture named `logo.*` in `fastfetch/` of that repo (linked
to `~/Pictures/fastfetch`) and fastfetch shows it in kitty instead of the distro logo.

After each change Matugen (`dotfiles/.config/matugen/config.toml`, one `[templates.X]` block
per app) writes matching colors for rofi, Waybar, kitty, the Control Center, the Settings
panel, the Hyprland borders, hyprlock, GTK 3, GTK 4, swaync, Qt (qt6ct), KDE apps, Firefox,
yazi, cava, btop, rmpc, yt-x, navi and the zsh command colors. Some templates have a
`post_hook` that reloads the app (kitty, swaync). Waybar picks up its new colors by itself
(`reload_style_on_change`); it is never sent SIGUSR2, which crashed Waybar 0.15. The colors
are made after the 1.2 s wallpaper transition so it stays smooth.

**Settings > Appearance** (`settings appearance`, or `colors` with no argument) picks what
Matugen starts from: one of the colors found in the wallpaper (the first one is the
default), a preset or a typed `#rrggbb`, plus the style (Matugen scheme: tonal, vibrant,
expressive, neutral, mono, fidelity, content, rainbow, fruit salad). A click recolors the
whole desktop at once; Auto goes back to `wallpaper:0 tonal-spot`. A fixed color stays when
the wallpaper changes. Same from a terminal:

```
colors status                   # the saved choice, e.g. "wallpaper:0 vibrant"
colors set '#5b8def' vibrant    # a fixed color
colors set wallpaper:2          # the third color of the wallpaper, keep the scheme
colors auto                     # back to the default
colors apply                    # recolor from the saved choice (after editing a template)
colors candidates               # the colors found in the current wallpaper
```

The choice is stored in `~/.local/state/colors/choice`.

Translucent apps: list them in `translucent` at the top of
`dotfiles/.config/hypr/conf/windowrules.lua` (class, opacity focused / unfocused; Telegram
is there). It fades the whole window, text included; kitty fades only its background with
its own `background_opacity`. To find an app's class: navi (Ctrl+G), "window class", or
`hyprctl clients`.

### Theme packs

A theme pack is a folder `themes/<name>/` that changes the whole look at once. Switch in
Settings > Appearance (Theme), or:

```
theme                 # list the packs, * = active
theme apply cosmos    # switch
theme grub            # install the active pack's GRUB theme (sudo; shows at next boot)
```

`theme apply` checks the pack's `hyprland.lua` with `Hyprland --verify-config` first (a
broken pack changes nothing), links `~/.config/theme` to the pack, writes the tokens,
reloads Hyprland, sets the pack's wallpaper (or puts back the one from before), recolors
and restarts Waybar. The lock screen and fastfetch change the next time they start.

| File in the pack | Required | Read by | What it changes |
|---|---|---|---|
| `theme.conf` | yes | `bin/theme` | `DESCRIPTION`, `WALLPAPER` (a file in the pack, optional), `GRUB` (a theme under `setup/system/grub-theme`, optional) |
| `hyprland.lua` | yes | end of `hypr/hyprland.lua` | borders, gaps, animations, anything Hyprland |
| `hyprlock.conf` | yes | `hypr/hyprlock.conf` (`source`) | the lock screen layout (labels, clock, input field) |
| `waybar.json` | yes | `bin/waybar-launch` | per-module keys merged into `waybar/config` (e.g. workspace icons) |
| `waybar.css` | yes | top of `waybar/style.in.css` | style overrides; use `window#waybar` selectors so they win |
| `rofi.rasi` | yes | end of `rofi/config.rasi` | launcher overrides (may be just a comment) |
| `tokens.conf` | no | `bin/tokens` | only the [design tokens](#design-tokens) that differ from `themes/default/tokens.conf` |
| `fastfetch.jsonc`, `fastfetch-logo.*` | no | the `fastfetch` function in `.zshrc` | the terminal greeting |

The two packs:

- **default**: plain; Roman workspace numerals, a clock lock screen, the distro fastfetch,
  macOS-style panels (`UI_STYLE=mac`).
- **cosmos**: space; galaxy wallpaper, glowing gradient window borders, planet-dot
  workspaces, a HUD lock screen in the mono font, sci-fi HUD panels (`UI_STYLE=hud`).

### Design tokens

`themes/default/tokens.conf` is the one place for the shapes and fonts of the desktop. A
pack's own `tokens.conf` lists only the keys it changes (cosmos: `UI_STYLE=hud`).

| Key | Default | Meaning |
|---|---|---|
| `RADIUS_LG` | 8 | corners of big surfaces: the bar, launcher, Settings, power tiles, notifications, windows |
| `RADIUS_MD` | 6 | cards, rows, buttons, Waybar pills |
| `RADIUS_SM` | 4 | small parts: text fields, inner segments, chips |
| `BORDER` | 1 | border width of panels (Hyprland's 2 px focus border is separate on purpose) |
| `FONT_UI`, `FONT_UI_SIZE` | Noto Sans, 11 | interface text |
| `FONT_MONO`, `FONT_MONO_SIZE` | FiraCode Nerd Font, 11 | terminal, numbers, icon glyphs |
| `DIM` | 0.30 | darkness of the backdrop behind panels and dialogs |
| `PANEL_ALPHA` | 0.82 | opacity of panel and bar backgrounds (the blurred desktop shows through) |
| `UI_STYLE` | mac | `mac`: filled cards; `hud`: outlined rows, UPPERCASE spaced labels, corner brackets, mono font |

`bin/tokens` validates the values (whole numbers, 0–1 ranges, `mac`/`hud`) and writes one
file per format to `~/.config/theme-tokens/`. `tokens show` prints every value and the pack
it comes from. Who reads what:

| Output | Used by | How |
|---|---|---|
| `tokens.rasi` | every rofi menu | `@import` it, then `border-radius: @radius-lg; border: @border-w; font: @font-ui;` (`@border-w solid` does **not** parse in rofi) |
| `tokens.css` | Control Center, swaync, screenshot preview (GTK 4) | `@import url("../theme-tokens/tokens.css");` then `var(--radius-lg)`, `alpha(@color, var(--panel-alpha))` |
| `tokens.json` | Quickshell: Settings, wallpaper picker | `shared/Tokens.qml` reads it (each config has a `Tokens.qml` link to it) |
| `tokens.env` | Waybar (GTK 3 has no CSS variables) | `waybar-launch` fills the double-braced keys in `waybar/style.in.css` |
| `tokens.lua` | Hyprland | `hypr/conf/decoration.lua`: `rounding = tokens.radius_lg` |
| `tokens.conf` | hyprlock | `$radius_lg`, `$font_ui`, `$font_mono` |
| `kitty.conf` | kitty | `include` for `font_family` (the size stays in `kitty.conf`) |

Two places cannot read tokens and carry a copy with a comment: the rofi background alpha in
the Matugen template (`d1` = 0.82 = `PANEL_ALPHA`) and the two oversized launcher fonts
(the search line and its glyph). Sizes stay per component (Waybar 13 px, Settings in its
own pixels); tokens hold the families.

#### Check that nothing is hard-coded

```
cd ~/Documents/personal/dotfiles-hyprland
grep -rnE "(border-radius|rounding)[ :=]+[0-9]+(px)?|radius: [0-9]+ \*" dotfiles themes bin \
  | grep -vE "firefox-chrome|99px|100px|100%|50%|: 0;|rounding = -1"
grep -rnE "FiraCode Nerd Font|Noto Sans" dotfiles themes bin | grep -vE "firefox-chrome|tokens"
```

Expected output (deliberate, leave it): in `matugen/templates/swaync.css` the
`--border-radius: 12px` of swaync's own default style copied at the top (the repo's block
further down overrides it) and a `12px` inside a comment; the fallback values used before
the token files exist in `quickshell/shared/Tokens.qml`, `hypr/hyprlock.conf` and
`bin/screenshot-preview`; mpv's OSD font. Anything else these print is not synced to the
tokens yet. Round things (`99px`, `width / 2`) are shapes, not radii.

---

## Components

| Role | Program |
|---|---|
| Compositor | Hyprland (Lua config: `~/.config/hypr/hyprland.lua` loads `conf/*.lua`, then the theme pack's `hyprland.lua`) |
| Bar | Waybar, minimal like macOS (see [Waybar](#waybar)) |
| Launcher, menus | rofi 2 (Wayland), Spotlight-style launcher with web search; power menu, Force quit dialog, clipboard, calculator, timer, capture toolbar |
| Settings | Quickshell panel, macOS System Settings style (see [Settings panel](#settings-panel)) |
| Control Center | GTK 4 + layer-shell panel from the Waybar icon (`bin/control-center`) |
| Terminal | kitty (its image protocol keeps transparency for pictures in terminal apps) |
| Shell | zsh with powerlevel10k, autosuggestions, syntax highlighting, history substring search |
| Notifications, OSD | swaync: compact translucent cards; OSD popups for volume, mic and brightness (`bin/osd`) |
| Files | Nautilus (GUI, no window buttons, Finder-like list view), yazi (terminal) |
| Editor | Neovim with an own config built stage by stage (`dotfiles/.config/nvim`, roadmap `docs/neovim.md`); VS Code as the fallback |
| Claude Code | Status line: folder, git branch, model, context bar, 5-hour / 7-day plan usage (`dotfiles/.claude/statusline.sh`; `setup/link-dotfiles.sh` adds the `statusLine` entry to `~/.claude/settings.json`) |
| Wallpaper, colors | awww, Matugen |
| Lock, idle, night light | hyprlock, hypridle, hyprsunset |
| Input method | fcitx5 with Lotus (Vietnamese, Telex; a lone `w` types ư everywhere, `ww` types w), Bamboo as fallback |
| Clipboard | cliphist |
| Screenshots, recording | grim, slurp, satty, wf-recorder |
| Polkit, secrets | hyprpolkitagent, gnome-keyring |
| Audio, Bluetooth, Wi-Fi | Settings sections; wiremix, bluetui and nmtui stay installed for the terminal |
| Browser | Firefox (FF Ultima theme, see [Firefox](#firefox)) |
| Media | mpv (video, also for yt-x; resumes where you left off, but a video played to the end starts over), yt-dlp (downloads to `~/Videos/YouTube`), yt-x (YouTube in the terminal; videos open as a small window in the bottom-right corner, pinned to every workspace), MPD + rmpc (music in `~/Music`; player view with the record picture, queue and library as icon tabs, a keys tab); media keys control mpv and MPD through MPRIS |

The full package list is the `packages` array in `setup/setup-arch.sh`.

---

## Desktop panels in detail

### Waybar

| File | Role |
|---|---|
| `dotfiles/.config/waybar/config` | the bar: modules and their settings (JSON with `//` comment lines) |
| `dotfiles/.config/waybar/style.in.css` | the style **template**: double-braced token keys are filled in |
| `dotfiles/.config/waybar/colors.css` | Matugen colors (generated) |
| `themes/<pack>/waybar.json`, `waybar.css` | the pack's module keys and style overrides |
| `bin/waybar-launch` | writes `$XDG_RUNTIME_DIR/waybar/config.json` (one bar per screen, 77 % of its width, pack keys merged) and `style.css` (tokens filled), then restarts Waybar |

Modules, left to right: launcher (left click: launcher, middle click: wallpaper picker), the
active app's name, CPU / RAM (`bin/sysinfo-bar`); workspaces; the recording stop button and
timer countdown (only while one runs), tray + Wi-Fi + battery (`group/status`), the Settings
gear, the Control Center icon, the notification bell (right click: Do Not Disturb), the
clock (click: notifications), the power button.

Restart it with SUPER+SHIFT+B or `waybar-launch` (needed after editing `style.in.css` or
the config; Waybar only reloads the generated `style.css` by itself). Its log:
`journalctl --user -t waybar`. Never `pkill -USR2 waybar`.

### Launcher

`bin/launcher` (SUPER+Space, SUPER+S, Fn+F12, the Waybar launcher button): one rofi list of
apps and web search, macOS Spotlight style. Enter starts the selected app; when nothing
matches, Enter searches the web; Ctrl+Enter always searches or opens the typed address
(`github.com`, `localhost:5173`, `192.168.1.1`, `https://…`) in Firefox. How: a rofi
`combi` of a `web` script mode (`bin/web-search`, no rows of its own) and `drun`; typed text
that matches no row is handed to the first mode. Look: `rofi/config.rasi`. One click runs
an entry (`me-accept-entry: MousePrimary`, `hover-select`).

### Power menu and Force quit

`bin/power-menu` (SUPER+Escape, the Waybar power button): a 4 x 2 grid of tiles (rofi,
`rofi/config-power.rasi`, icons in `rofi/power-icons/`): Lock, Suspend, Hibernate,
Shutdown / Force quit, Logout, Reboot, BIOS. One highlighted tile follows both the mouse
and the arrow keys; a click or Enter runs it; letter keys l u h s f e r b run a tile
directly; Esc closes. The tiles and their commands are the `ITEMS` array at the top of the
script (`label|icon|key|command`).

`bin/force-quit` closes every window **outside workspace 1** after a macOS-style alert
(`rofi/config-confirm.rasi`, Cancel selected first): a normal close request first, then
SIGTERM / SIGKILL after 5 s for what is still open, except programs that also own a window
on workspace 1. Windows are closed by address only (a close dispatcher with a bad argument
acts on the focused window instead).

### Settings panel

`bin/settings` (SUPER+comma, the Waybar gear, rows in the Control Center): a Quickshell
panel in `dotfiles/.config/quickshell/settings/`. It starts on demand and quits when
closed; running `settings` again (or Esc, or a click outside) closes it. `settings
SECTION` opens a section: general, network, bluetooth, sound, display, power, storage,
system (About), appearance, configs.

| Section | File | What it does |
|---|---|---|
| General | `GeneralPage.qml` | you (picture from `~/.face`, else your initial) and a quick status; each row opens its section. Reads everything with small commands, no service modules |
| Wi-Fi | `NetworkPage.qml` | on/off, current network (IP, live speed), Ethernet, other networks with an inline password field |
| Bluetooth | `BluetoothPage.qml` | on/off, paired devices (connect, battery, forget), nearby devices (pair + trust + connect) |
| Sound | `SoundPage.qml` | output and input volume, devices, input level, per-app volume |
| Displays | `DisplayPage.qml` | brightness, keyboard backlight, night light, screens, external monitor mode |
| Battery | `PowerPage.qml` | charge, health, power mode, charge limit, Caffeine, lid / idle summary |
| Storage | `StoragePage.qml` | disk, biggest folders, swap, Timeshift and package cache shortcuts |
| About | `SystemPage.qml` | model, CPU, GPU, versions, pending updates (`sysupdate`), tools |
| Appearance | `AppearancePage.qml` | wallpaper, colors (wallpaper colors, presets, `#rrggbb`, style), theme pack |
| Configs | `ConfigsPage.qml` | open config files in nvim, reload Hyprland (verified first), restart Waybar |

How it is built:

- `shell.qml`: the window, sidebar (`sections` list: key, label, glyph) and the content
  `Loader`. **Only the open section is loaded**, so NetworkManager, BlueZ, PipeWire and
  UPower start, and Wi-Fi / Bluetooth are scanned, only while their section is open (scans
  run through `nmcli` / `bluetoothctl` in their own process: Quickshell's scan switches
  are blocking D-Bus calls that froze the panel).
- Nothing shows until the page is loaded and 3 frames were drawn (600 ms at most), then the
  whole panel fades in at once (prewarm at opacity 0.004, idea from 43PR/dotfiles).
- Shared parts: `Pal.qml` (palette from `rofi/colors.rasi`, sizes, `hud` flag, `label()`),
  `Page.qml` (title + scrolling column), `Group.qml` (a card of rows), `SRow.qml` (one row:
  icon, title, subtitle, controls on the right), `Toggle.qml`, `Sld.qml` (slider),
  `Btn.qml`, `Seg.qml` (segmented control), `Tokens.qml` (link to `../shared/Tokens.qml`).
- Icons are flat Nerd Font glyphs in the text colour; only the warning colour (low
  battery, muted mic) and the Wi-Fi signal opacity carry meaning. The accent colour is
  kept for what is chosen.
- Pages close the panel with `Pal.closeRequested()` and switch sections with
  `Pal.navigate(key)`; `Pal.open` is true while it is on screen (polling timers use it).
- `QS_SELFTEST=1 qs -n -c settings` loads every section without a window and logs
  `SELFTEST <section> ok|error|timeout` (used by `dotfiles-verify`).

### Control Center

`bin/control-center` (Python, GTK 4 + gtk4-layer-shell; the Waybar icon): Wi-Fi and
Bluetooth switches (their names open the Settings section), Do Not Disturb, Caffeine, now
playing (x stops the player), brightness and volume sliders ("Sound" opens Settings >
Sound), and small tiles: charge limit, power mode, record, screenshot, wallpaper, lock,
notifications, power menu. Look: `dotfiles/.config/control-center/style.css` with
`colors.css` (Matugen) and the tokens. It is started with `LD_PRELOAD` of the layer-shell
library (the library must load before libwayland); its children do not inherit it.

### Notifications and OSD

swaync shows notifications as compact cards; its style is the Matugen template
`matugen/templates/swaync.css` (written to `~/.config/swaync/style.css`, reloaded by
Matugen's post hook). `bin/osd` changes volume, mic and brightness and shows a progress
popup as a low-urgency notification (mono font for the numbers).

The mic LED on F4 is lit while the mic is **live** and off when muted. `bin/osd` detaches
the kernel's `audio-micmute` trigger with its first write and sets the LED through
brightnessctl (logind, no root); the headset jack's ALSA Capture switch still follows the
mute state. `osd mic sync` runs at login and whenever Settings > Sound sees a mute change.

### Screenshots and recordings

Screenshots are saved to `~/Pictures/Screenshots`, copied to the clipboard and shown in a
small preview (`bin/screenshot-preview`, GTK 4: drag and drop, click to edit). Recordings
go to `~/Videos/Recordings`; while recording, Waybar shows a red stop button with the
elapsed time, and when it stops the same preview shows the video. The capture toolbar
(`bin/capture-menu`, SUPER+CTRL+4 / 5) is a rofi row at the bottom of the screen.

### Lock screen

hyprlock: `dotfiles/.config/hypr/hyprlock.conf` sets the general options, sources the
Matugen colors, the tokens and then the pack's layout (`themes/<pack>/hyprlock.conf`).
SUPER+L locks; SUPER+CTRL+L repairs a black lock screen (`bin/lock-recover`, the session
stays locked). After changing anything here, press SUPER+L once to check: hyprlock has no
way to test a config without locking.

---

## Key bindings

Defined in `dotfiles/.config/hypr/conf/binds.lua` (`hl.bind(keys, action)`; `mainMod` is
SUPER).

| Keys | Action |
|---|---|
| SUPER + Return | kitty |
| SUPER + Space | Launcher (also Fn+F12 and SUPER+S): apps and web search in one list; Enter starts the app or, with no match, searches the web; Ctrl+Enter always searches / opens the address |
| SUPER + B | Browser |
| SUPER + E | Nautilus |
| SUPER + SHIFT + E | yazi in kitty |
| SUPER + V | Clipboard history (Shift+Enter deletes an entry) |
| SUPER + = | Calculator (rofi-calc, also units and currencies): Enter copies the result |
| SUPER + SHIFT + T | Timer or alarm: `10m tea`, `1h30m`, `07:30 wake up`; countdown on Waybar, pick one to cancel |
| SUPER + W / SUPER + SHIFT + W | Pick a wallpaper / random wallpaper |
| SUPER + A | Audio visualizer (cava) on/off |
| SUPER + SHIFT + C | Caffeine: no idle lock or suspend |
| SUPER + , | Settings panel (also the gear icon in Waybar); again closes it |
| SUPER + Escape | Power menu; again closes it |
| SUPER + L | Lock the screen |
| SUPER + CTRL + L | Black lock screen: turn the screens on and restart hyprlock (works while locked) |
| SUPER + CTRL + Escape | Way out of a virtual machine or remote desktop that holds the keyboard: leaves fullscreen, back to the previous workspace (always reaches Hyprland) |
| SUPER + CTRL + R | Reload the Hyprland config, restores all screens |
| SUPER + SHIFT + B | Restart Waybar |
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
| Volume, mic (F4), brightness keys | Change the value and show an OSD popup |
| Media keys | play/pause, next, previous, stop on the most recently active player (playerctld) |
| Lid | with an external monitor: only the monitor stays on; otherwise logind suspends (see below) |

Workspaces 1–5 stay on the laptop screen and 6–10 on the first external monitor.

---

## Sleep, lid and hibernate

| When | What happens | Where |
|---|---|---|
| Idle 5 min | the laptop panel dims | `hypr/hypridle.conf` |
| Idle 10 min | lock (hyprlock) | `hypr/hypridle.conf` |
| Idle 11 min | screens off | `hypr/hypridle.conf` |
| Idle 30 min, nothing playing | on battery: suspend, then hibernate 30 min later; docked (lid closed, external monitor): plain suspend so USB keys wake it; plugged in, lid open: stays awake | `hypr/hypridle.conf` |
| Lid closed | suspend, hibernate after 30 min (battery and AC); with an external monitor plugged in: nothing, the monitor stays on | `/etc/systemd/logind.conf.d/lid.conf`, `/etc/systemd/sleep.conf.d/hibernate.conf` (sources in `setup/system/`) |
| Caffeine on | none of the above (an inhibitor for idle, sleep and the lid) | `bin/caffeine` |

Hibernate is set up by `setup/enable-hibernate.sh` (asked by `setup-arch.sh`; run as
`sudo bash setup/enable-hibernate.sh`, safe to run again): a btrfs swapfile in its own
`@swap` subvolume mounted at `/swap` (size = RAM + 5 GB, low priority so zram stays the
main swap), `resume=UUID=… resume_offset=…` in `/etc/default/grub`, the `resume` hook after
`encrypt` in `/etc/mkinitcpio.conf` (not needed with a systemd initramfs), and the two
systemd files above. It takes a Timeshift snapshot and backs up fstab, grub and
mkinitcpio.conf (`*.bak-hibernate-<time>`) first. After RAM upgrades: `swapoff
/swap/swapfile`, delete it, run the script again. Test with `systemctl hibernate`: the
laptop turns off; on power-on GRUB asks for the LUKS passphrase, then the session comes back
to the lock screen. Notes and measurements: `docs/sleep.md`.

---

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

- **Battery charge thresholds 75/80**: a oneshot service sets them at boot. The Control
  Center tile and Settings > Battery (`bin/battery-mode`) switch between 75–80 % and a full
  100 % charge through a root-owned helper and a polkit action (password each time). A
  reboot always returns to 75–80 %.
- **gnome-keyring via PAM**: unlocked with the login password (sddm, greetd or console
  login) and kept in sync when the password changes.
- **zram**: size = RAM, zstd, plus the vm sysctls for zram (`99-vm-zram.conf`). A new
  size applies at the next boot.
- **earlyoom**: stops the biggest process (test browsers first) before memory runs out;
  avoids the desktop, terminal, editor, lock screen, audio and input method.
- **Firefox policy**: installs uBlock Origin, Proton Pass and Unhook from addons.mozilla.org.
- **Firewall** (nftables, `setup/system/nftables.conf`): nothing from the network may
  connect in, replies to the laptop's own connections pass. Ports published by Docker
  are reachable from this laptop only; containers and libvirt VMs still reach the host and
  the internet.
- **faillock**: 5 wrong passwords (lock screen, sudo, login) within 15 minutes lock
  the account for 2 minutes instead of 3 for 10 minutes. hyprlock also ignores Enter on
  an empty field, so the key that wakes the laptop is not a failed attempt.
- **Bluetooth**: bluetoothd runs without its GATT battery plugin, so headsets that report
  0 % over GATT but the real level over HFP (Marshall Major V) show the HFP level,
  forwarded by PipeWire. Logitech devices report through the kernel HID++ driver.
- **Timeshift** (btrfs): daily 5, weekly 3, `/home` excluded; grub-btrfsd keeps the GRUB
  snapshot menu up to date, cronie runs the schedule. timeshift-autosnap takes a
  snapshot before every pacman upgrade.
- **Lid**: `logind.conf.d/lid.conf` and `sleep.conf.d/hibernate.conf` once hibernate is set
  up (see [Sleep, lid and hibernate](#sleep-lid-and-hibernate)).
- **GRUB theme** Cosmos (`setup/system/grub-theme/cosmos`).

## Pacman hooks and dotfiles-verify

`setup/install-pacman-hooks.sh` (run by `setup-arch.sh`, needs sudo; run it again after
editing `setup/pacman-hooks/`) installs four hooks to `/etc/pacman.d/hooks/` and their
scripts root-owned to `/usr/local/lib/dotfiles-hyprland/`, because a root hook must never
execute a file inside `$HOME`. Each runs after the transaction, prints `:: … OK` or
`==> WARNING: …` in the pacman output, and **never blocks an update**.

| Hook | After an upgrade of | Checks |
|---|---|---|
| `hyprland-verify-config` | hyprland | `Hyprland --verify-config` on every user's config |
| `matugen-verify-config` | matugen | renders every template into a temp folder (real files untouched, no post hooks); names template and line of each error or left-over `{{…}}` |
| `rmpc-verify-config` | rmpc | starts rmpc for two seconds with each user's config and theme, prints its error |
| `dotfiles-verify` | quickshell, qt6-base, qt6-declarative, rofi, rofi-calc, waybar, gtk3, gtk4, gtk4-layer-shell, python, python-gobject, swaync, kitty, hyprlock, hypridle | runs each user's own `~/.local/bin/dotfiles-verify` **as that user** (runuser, clean environment, with the Wayland session if there is one) |

`bin/dotfiles-verify` (also by hand, any time; exit 1 when something failed) checks:

- the design tokens are valid;
- every rofi theme parses (as `-theme`: loaded as `-config`, rofi skips a broken theme silently);
- the Waybar config (with the pack's `waybar.json`) is valid JSON and the filled style
  (`waybar-launch --render-style FILE`) parses as GTK 3 CSS;
- the GTK 4 styles of the Control Center, swaync and the screenshot preview parse;
- `bin/control-center` and `bin/screenshot-preview` compile and find GTK 4 and gtk4-layer-shell;
- kitty reads its config without complaints;
- Settings loads every section and the wallpaper picker loads (`QS_SELFTEST=1`, no window;
  needs the Wayland session, skipped from a TTY: run it after logging in);
- hyprlock's sourced files exist; after a hyprlock / hypridle upgrade it asks for a SUPER+L test.

Each check was proven by breaking a copy of the configs in a fake `HOME`. To try a change
the same way: copy `~/.config/<app>` into a temp folder `X/.config/`, break it, then run
`HOME=X XDG_CONFIG_HOME=X/.config dotfiles-verify`.

---

## Scripts

All in `bin/`, linked to `~/.local/bin/`. Every script starts with a comment block that
explains its usage; read it with `head -30 bin/<name>`.

| Script | Purpose |
|---|---|
| `launcher`, `web-search` | Spotlight-style launcher; its web part (`web-search "text"` opens it directly) |
| `settings` | Settings panel (`settings SECTION`) |
| `control-center` | Control Center panel |
| `power-menu`, `force-quit` | Power menu; close everything outside workspace 1 |
| `theme` | Switch theme packs (`theme apply NAME`, `theme grub`, `theme list-tsv`) |
| `tokens` | Write the design tokens (`tokens show` lists them) |
| `colors` | Where Matugen starts from (`status`, `set`, `auto`, `apply`, `candidates`; no argument: Settings > Appearance) |
| `wallpaper` | Pick, set and theme from the wallpaper (`select`, `select-rofi`, `random`, `set FILE`, `restore`) |
| `waybar-launch` | (Re)start Waybar; `--render-style FILE` only writes the filled style |
| `dotfiles-verify` | Check the bar, menus, panels and lock screen with the installed versions |
| `screenshot`, `screenshot-preview` | Screenshots with file, clipboard and preview |
| `screenrec`, `rec-status` | Start/stop screen recording; the Waybar stop button |
| `capture-menu` | Screenshot / recording toolbar (rofi) |
| `clipboard` | Clipboard history picker |
| `calc`, `calc-qalc` | Calculator under the bar (rofi-calc): units, currencies, percentages; Enter copies. `calc-qalc` is its qalc wrapper ("15% of 2300000", Vietnamese number format), also usable in a terminal |
| `timer` | Countdown timers and alarms as systemd user timers (ring after sleep too), Waybar countdown, snooze from the notification |
| `caffeine` | Keep the laptop awake, also handles the lid while on |
| `display-toggle` | External monitor cycle (Fn+F7); lid close with a monitor leaves only the monitor on |
| `dpms` | Turn the screens on or off only when needed |
| `lock-recover` | Fix a black or dead lock screen, the session stays locked |
| `osd` | Volume, mic and brightness with a popup; the mic LED |
| `battery-mode` | Charge limit 75–80 % or 100 % |
| `powermode-notify` | Notification when the power profile changes (Fn+F8) |
| `media-clear` | Stop every player: mpv quits, Firefox and mpd stop |
| `lock-media` | Song and buttons on the lock screen |
| `yt-music` | Download songs as best-quality audio into ~/Music/<artist>/<title>/ with a record picture |
| `vinyl-cover` | Record picture for rmpc: square sleeve with a vinyl pulled half out |
| `rmpc-notify` | rmpc song-change notification with the album art |
| `sysupdate` | Guided update (see [Updating](#updating)) |
| `sysinfo-bar`, `sysmetrics`, `syslive` | CPU/RAM on Waybar, metrics, live status view |
| `sysreport` | One-shot machine health report to `~/sysreport` |
| `cava-toggle` | Floating audio visualizer |
| `firefox-theme` | Link the Firefox theme into the default profile |
| `navi` (Ctrl+G in zsh) | Command notebook of this setup; add your own in `dotfiles/.config/navi/cheats/dotfiles.cheat`. `tldr <command>` for common commands |

---

## How do I…

Every recipe edits files in the repo (they are linked into `$HOME`), then applies the
change. Commit when it works.

### Change a corner radius, the border, a font or the panel opacity everywhere

1. Edit `themes/default/tokens.conf` (or only the active pack's `tokens.conf` to change one
   theme).
2. `tokens` (writes `~/.config/theme-tokens/`), then apply: `waybar-launch` (bar), SUPER+CTRL+R
   (window corners), `colors apply` (swaync and the rest reload with new colors). rofi,
   Settings, the Control Center and kitty read the tokens the next time they open.
3. `dotfiles-verify`.

### Make a new theme pack

1. `cp -r themes/default themes/mine`, edit `theme.conf` (`DESCRIPTION`, optional
   `WALLPAPER=wallpaper.jpg` with the file in the folder).
2. Change what you want in its `hyprland.lua`, `hyprlock.conf`, `waybar.json`, `waybar.css`,
   `rofi.rasi`. Keep every required file (even as a comment) or `theme apply` refuses.
3. For shapes and fonts write a `tokens.conf` with only the keys that differ (e.g.
   `UI_STYLE=hud`, `RADIUS_LG=4`).
4. `theme apply mine`, then `dotfiles-verify`.

### Add or change a key binding

1. Edit `dotfiles/.config/hypr/conf/binds.lua`: `hl.bind(mainMod .. " + K", exec("command"))`.
   Key names: `comma`, `equal`, `Escape`, `Print`, `XF86…` (find one with `wev`).
2. Hyprland reloads by itself when the file is saved; check `hyprctl configerrors` (empty =
   fine) and add the row to the [Key bindings](#key-bindings) table.

### Add a Waybar module

1. Add its settings to `dotfiles/.config/waybar/config` (a `"custom/name": { "exec": …,
   "on-click": … }` block) and its name to `modules-left` / `modules-center` /
   `modules-right` (or inside `group/status`).
2. Style it in `style.in.css` (`#custom-name { … }`), using `{{RADIUS_MD}}` etc. for corners.
3. `waybar-launch` (or SUPER+SHIFT+B), then `dotfiles-verify`.

### Add a section to Settings

1. Create `dotfiles/.config/quickshell/settings/<Key>Page.qml`:
   ```qml
   import QtQuick
   import Quickshell
   Page {
       id: p
       title: "Example"
       Group {
           title: "Things"
           SRow { icon: ""; title: "A row"; subtitle: "with a subtitle"
                  Btn { text: "Do it"; onClicked: Quickshell.execDetached(["notify-send", "hi"]) } }
       }
   }
   ```
2. Add `{ key: "<Key>", label: "Example", glyph: "" }` to `sections` in `shell.qml`
   (`{ key: "" }` is a gap between groups).
3. Start polling timers with `running: Pal.open`; start services or scans only in this page
   (lazy); never call `Qt.quit()` (use `Pal.closeRequested()`).
4. `settings <key>` to look at it, `dotfiles-verify` (the self-test loads it too).

### Add a rofi menu

1. Copy `dotfiles/.config/rofi/config-timer.rasi` to `config-<name>.rasi`; keep the
   `@import "colors.rasi"` and `@import "~/.config/theme-tokens/tokens.rasi"` lines and use
   `@radius-lg`, `@radius-md`, `@border-w`, `@font-ui` / `@font-mono`. Never write `/*`
   inside a comment (rofi nests comments and would skip the rest of the file).
2. Call it from a script: `printf 'a\nb\n' | rofi -dmenu -config ~/.config/rofi/config-<name>.rasi`.
3. `dotfiles-verify` checks the new theme automatically.

### Add an app to the Matugen colors

1. Write a template in `dotfiles/.config/matugen/templates/` with `{{colors.primary.default.hex}}`
   etc. (copy an existing one).
2. Add a `[templates.<name>]` block to `matugen/config.toml` (`input_path`, `output_path`,
   optional `post_hook` to reload the app); git-ignore the output in that app's folder.
3. `colors apply`; `/usr/local/lib/dotfiles-hyprland/matugen-verify-config` checks every
   template.

### Make an app translucent

Add it to `translucent` at the top of `hypr/conf/windowrules.lua` (class, opacity focused,
unfocused). Blur behind layer surfaces (panels) is a `hl.layer_rule` by namespace in the
same file.

### Change what the lid or idle does

Idle steps: `hypr/hypridle.conf` (restart hypridle: `pkill hypridle; hypridle &`). Lid and
the hibernate delay: `setup/system/logind.conf.d/lid.conf` and
`setup/system/sleep.conf.d/hibernate.conf`, installed with `sudo install -m 644 … /etc/systemd/…`
(or `setup/install-system-files.sh`), then `sudo systemctl kill -s HUP systemd-logind`
(**never** restart systemd-logind: it ends the session).

### Add a program to a fresh install

Add the package to `packages` in `setup/setup-arch.sh`. If a hook should watch it, add a
`Target =` line to `setup/pacman-hooks/dotfiles-verify.hook` and a check to
`bin/dotfiles-verify`, then `setup/install-pacman-hooks.sh`.

---

## When something breaks

First, from any terminal or a TTY (Ctrl+Alt+F2):

```
dotfiles-verify                    # bar, menus, panels, lock screen files
hyprctl configerrors               # Hyprland config errors (from a TTY: hyprctl -i 0 configerrors)
Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
journalctl --user -t waybar -n 50  # Waybar's log
qs log -c settings                 # the last Settings run (Quickshell)
git -C ~/Documents/personal/dotfiles-hyprland status   # what changed
```

| Symptom | Fix |
|---|---|
| Black screen after an update | TTY2: `Hyprland --verify-config …`, fix the line it names; or boot a Timeshift snapshot from the GRUB menu |
| No bar | `waybar-launch`; if it says a design token is missing: `tokens`; see `journalctl --user -t waybar` |
| Bar or menus without colors | `wallpaper restore` (regenerates every color file) |
| Settings does not open | `qs log -c settings`; `QS_SELFTEST=1 qs -n -c settings` names the broken section |
| A rofi menu shows the default white theme | a parse error: `rofi -theme ~/.config/rofi/<file>.rasi -dump-theme` prints "Failed to parse" |
| Lock screen black or dead | SUPER+CTRL+L (works while locked); from a TTY: `lock-recover` |
| Lock screen does not appear at all | `hyprlock` from a terminal shows its error; check the sourced files exist (`dotfiles-verify`) |
| Everything looks wrong after `theme apply` | `theme apply default` |
| Shapes or fonts did not change | `tokens`, then restart the part (`waybar-launch`, SUPER+CTRL+R) |
| A hook warned during an update | read the warning, fix the file it names, run `dotfiles-verify` again |
| Need the old state back | Timeshift (Settings > Storage, or `sudo timeshift-launcher`), or a snapshot from the GRUB menu; for one file: `git checkout <file>` |

Monitor changes can be tried without a cable: `hyprctl output create headless`. From a TTY,
name the Hyprland instance: `hyprctl -i 0 reload`.

---

## Updating

Run `sysupdate` (`bin/sysupdate`, or Settings > About > Update): Arch news, the packages
that will change (kernel and Hyprland releases flagged), a power check, an optional manual
Timeshift snapshot, `yay -Syu` recorded to `~/.local/state/sysupdate/`, then a summary of
hook warnings, `.pacnew` files and whether to reboot. The pacman hooks above run during the
update. Step-by-step guide (Vietnamese): `docs/update.md`.

## License

GPL-3.0, like the upstream ML4W Hyprland Starter. The FF Ultima files in
`dotfiles/.config/firefox-chrome` are MPL 2.0.
