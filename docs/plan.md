<!-- ThinkPad T14 Gen 6 setup plan (Vietnamese). Moved here from a claude.ai page on
     2026-11-12 so it lives next to the config it describes. -->

# Kế hoạch setup ThinkPad T14 Gen 6

Cập nhật lần cuối: Nov 12, 2026 · @diablo harmonz

## Khi màn hình đen sau khi khóa hoặc mở máy

1. Bấm **SUPER + CTRL + L**: bật lại màn hình và màn khóa (chạy được cả khi đang khóa). Nhập mật khẩu như bình thường.
2. Nếu vẫn đen: **Ctrl + Alt + F3**, đăng nhập. Máy tự hỏi "Restore its lock screen now?", bấm **y**. Rồi **Ctrl + Alt + F1** và nhập mật khẩu.
3. Không mở thêm Hyprland ở TTY khác. Nếu vẫn không được: chụp `journalctl --user -t hypridle --since "-1h" | tail -30` rồi mới khởi động lại máy.

## Phím tắt Firefox (thanh công cụ và cột tab đang tự ẩn)

- Ctrl + L: gõ địa chỉ hoặc tìm kiếm; gõ `% ` rồi tên trang để tìm trong các tab đang mở
- Alt + 1…8: tới tab thứ 1–8; Alt + 9: tab cuối (trên Linux là Alt, không phải Ctrl)
- Ctrl + Tab / Ctrl + Shift + Tab: tab sau / tab trước; Ctrl + T / Ctrl + W: mở / đóng tab
- Ctrl + Alt + Z: hiện cột tab và giữ nguyên, bấm lại để về tự ẩn; rê chuột ra mép trái để xem tạm; thanh công cụ hiện khi rê lên mép trên hoặc Ctrl + L
- SUPER + S (ngoài Firefox): tìm nhanh trên web hoặc mở địa chỉ trong Firefox

## Yazi và LazyVim (tập làm việc trong terminal)

- Yazi (quản lý file): gõ `y` trong terminal hoặc SUPER + SHIFT + E. Phím: j/k lên xuống, h/l ra/vào thư mục, Space chọn, y copy, x cắt, p dán, d xoá vào thùng rác, r đổi tên, `.` hiện file ẩn, / tìm, z nhảy thư mục (zoxide), q thoát (terminal chuyển tới thư mục vừa xem).
- LazyVim (Neovim): `nvim` (hoặc vim, vi). Học phím Vim: trong nvim gõ `:Tutor`. Phím Space mở menu lệnh của LazyVim; Space Space tìm file; Space e cây thư mục; Space gg mở lazygit.
- Lộ trình: tuần đầu :Tutor + Yazi + lazygit; sau đó giải LeetCode trong LazyVim (thêm leetcode.nvim khi cần); dự án công việc vẫn dùng VS Code.
- Plugin LazyVim ghim phiên bản bằng `lazy-lock.json` trong repo; cập nhật bằng `:Lazy update` rồi commit file đó.

## Tình trạng hiện tại

Manjaro KDE đã cài xong và chạy ổn; Hyprland đang chạy thử trên Manjaro bằng repo dotfiles-hyprland; bộ cài Arch trong repo đã đủ gói và cấu hình (2026-11-12), còn lại phần mềm công việc và sao lưu.

- [x] Cài Manjaro 25.0.10 (KDE): xoá Windows, btrfs, mã hoá LUKS, không dùng swap trên ổ
- [x] Cập nhật toàn hệ thống (đổi mirror, cập nhật keyring, gỡ các gói lib32 cũ gây lỗi)
- [x] zram 5,7 GB (zstd), tự bật mỗi lần khởi động
- [x] Timeshift (btrfs): đã có snapshot sau cài đặt, lịch Daily giữ 5 bản
- [x] grub-btrfs: GRUB có mục Manjaro Linux snapshots, menu GRUB hiện 5 giây
- [x] BIOS và firmware SSD đã là bản mới nhất (fwupd); firmware Wi-Fi/Bluetooth MediaTek có sẵn
- [x] memtest86+ đã chạy 2 vòng (48 phút) ngày 11-08 và 4 vòng (2 giờ 26 phút) ngày 11-10, Errors = 0 cả hai lần

## Chuẩn bị bộ cài

Bộ cài phải sẵn sàng để cài lại trong một buổi khi cài lại; ghi vào đây mọi phần mềm và cấu hình bạn thực sự dùng.

- [ ] Xuất danh sách gói: pacman -Qqen > ~/pkglist-repo.txt và pacman -Qqem > ~/pkglist-aur.txt (làm lại ngay trước khi cài lại, khi hệ thống đã ổn định)
- [x] Kho GitHub Hyprland starter: đã fork thành dotfiles-hyprland, chạy trên Manjaro với Hyprland 0.56.2. Đã sửa lỗi cú pháp (gestures, pseudotile, togglesplit) và chuyển hẳn cấu hình sang định dạng Lua (hyprland.lua + conf/*.lua), nên Hyprland 0.57 bỏ .conf không còn ảnh hưởng. Đã kiểm tra nguồn: bản gốc khớp upstream mylinuxforwork/hyprland-starter; đã gỡ lệnh curl | bash, file AppImage và sửa bước cài yay trong setup-arch.sh
- [x] Dotfiles Hyprland trong repo dotfiles-hyprland (đã push, 2026-11-12): WezTerm, zsh (bản sao manjaro-zsh-config trong repo nên dùng được trên Arch), bộ gõ fcitx5 + Lotus (gõ không gạch chân, Ctrl + Space), hình nền awww + trình chọn SUPER + W, màu theo hình nền bằng Matugen (rofi, Waybar, swaync, WezTerm, GTK, Qt, KDE), Waybar kiểu Hyprlust, rofi SUPER + Space, Nautilus, swaync, nm-applet, blueman, pavucontrol, hypridle (khoá 10 phút), caffeine SUPER + Shift + C, hyprsunset, clipboard SUPER + V (10 mục, 5 phút), preview ảnh chụp kiểu macOS, polkit agent, gnome-keyring, phím chụp và quay màn hình, hàng phím Fn, Fn+F7 màn hình ngoài, thông báo chế độ nguồn. Mọi chữ trong code, config và thông báo viết bằng tiếng Anh
- [ ] Dotfiles còn lại: trình soạn thảo. (Bộ gõ fcitx5 + Lotus đã có cấu hình trong repo)
- [ ] Phần mềm công việc: Node, IDE/trình soạn thảo, Android Studio, công cụ khác (bổ sung dần)
- [x] Hình nền: repo git riêng tư diablo-harmonz/wallpapers ở ~/Documents/personal/wallpapers, ~/Pictures/Wallpapers là symlink trỏ vào đó (link-dotfiles.sh tự tạo) (không đưa vào repo dotfiles công khai vì là tranh của tác giả khác); thêm hình mới thì git add, commit, push trong ~/Documents/personal/wallpapers
- [ ] Chọn nơi lưu bản sao /home (ổ ngoài hoặc cloud); snapshot Timeshift không thay cho sao lưu
- [ ] Mật khẩu LUKS lưu trong trình quản lý mật khẩu (nên là mật khẩu dài: GRUB chỉ mở được khoá LUKS dạng PBKDF2)

## Thử bộ cài trong máy ảo (trước khi cài thật)

Chưa làm. Mục đích: chạy trọn quy trình cài Arch bằng repo trên một máy ảo UEFI có LUKS, nhất là setup/arch-boot-in-root.sh (đụng tới khoá LUKS và GRUB, không thử được trên Manjaro), trước khi cài lên máy thật. Mất khoảng 1 đến 2 giờ.

### 1. Dựng máy ảo trên Manjaro

- Chụp snapshot Timeshift trước: sudo timeshift --create --comments "Trước khi cài virt-manager" --tags O
- Cài: sudo pacman -S qemu-desktop virt-manager libvirt edk2-ovmf dnsmasq; bật sudo systemctl enable --now libvirtd.service; thêm nhóm sudo usermod -aG libvirt $USER rồi đăng xuất, đăng nhập lại
- Ổ đĩa ảo nằm trên btrfs: tắt copy-on-write cho thư mục chứa ảnh đĩa để máy ảo không chậm và không phân mảnh: sudo chattr +C /var/lib/libvirt/images (làm khi thư mục còn trống)
- Tải ISO Arch mới nhất từ archlinux.org/download và kiểm tra chữ ký hoặc checksum
- Tạo máy ảo trong virt-manager: Local install media, chọn ISO; RAM 4096 MB, 2 đến 4 CPU; ổ 40 GB; trước khi bấm Finish tick Customize configuration: Overview, Firmware chọn UEFI (OVMF, không chọn bản secboot); Video chọn Virtio và bật 3D acceleration; Display Spice chọn Listen type None và OpenGL bật (Hyprland cần tăng tốc đồ hoạ)
- Nếu Hyprland trong máy ảo không lên được: bỏ dấu -- ở hai dòng For KVM virtual machines trong conf/environments.lua (WLR_NO_HARDWARE_CURSORS, WLR_RENDERER_ALLOW_SOFTWARE), chỉ dùng trong máy ảo, không commit

### 2. Chạy quy trình cài như máy thật

0. archinstall với đúng các lựa chọn ở mục Cài Arch Minimal và Hyprland (GRUB, btrfs mặc định, LUKS, EFI ở /boot, không display manager); dùng một mật khẩu LUKS thử, không dùng mật khẩu thật
1. Chroot: pacman -S git, clone repo, chạy setup/arch-boot-in-root.sh; tất cả dòng kiểm tra phải ok
2. Khởi động lại, setup/setup-arch.sh, setup/link-dotfiles.sh, wallpaper restore, đăng xuất và đăng nhập lại ở TTY1

### 3. Danh sách kiểm tra

- [ ] Khởi động: GRUB hỏi mật khẩu LUKS đúng một lần (không hỏi lại ở initramfs); menu GRUB hiện 5 giây; findmnt /boot/efi là phân vùng EFI; ls /boot thấy vmlinuz-linux
- [ ] Đăng nhập: TTY1 hỏi tài khoản và mật khẩu, Hyprland tự chạy; SUPER + M quay về màn hình đăng nhập; TTY2 (Ctrl+Alt+F2) vẫn là shell thường
- [ ] Timeshift và rollback: sudo timeshift --list có snapshot đầu tiên; cài thử một gói nhỏ (timeshift-autosnap phải tạo snapshot trước khi cài); menu GRUB có mục Arch Linux snapshots; khởi động thử vào snapshot cũ rồi khôi phục bằng sudo timeshift --restore; quan trọng nhất: cập nhật kernel (sudo pacman -Syu khi có linux mới, hoặc cài linux-lts) rồi khôi phục snapshot trước đó, máy vẫn phải khởi động được
- [ ] Hệ thống: zramctl có zram0; systemctl --failed trống; NetworkManager, bluetooth, power-profiles-daemon, cronie, grub-btrfsd đang chạy; shell mặc định là zsh, prompt powerlevel10k và gợi ý lệnh có
- [ ] Keyring và polkit: seahorse thấy keyring Login đã mở khoá sau khi đăng nhập TTY (không hỏi thêm mật khẩu); pkexec true hiện hộp thoại mật khẩu
- [ ] Giao diện: Waybar đủ mục (đồng hồ, workspace, khay, hai ngăn trượt); SUPER + W đổi hình nền và màu Waybar, rofi, WezTerm, Nautilus (GTK), Qt đổi theo; bấm icon âm lượng mở wiremix, icon Bluetooth mở bluetui; con trỏ Breeze; font và icon không lỗi
- [ ] Tiện ích: gõ tiếng Việt bằng Lotus trong WezTerm và trình duyệt, không gạch chân (fcitx5-lotus-server đang chạy); SUPER + V dán chữ và ảnh; Shift + Print hiện preview, kéo thả được; SUPER + L khoá, hypridle khoá sau 10 phút; caffeine bật tắt được; thông báo swaync hiện
- [ ] Ghi lại mọi lỗi hoặc gói thiếu, sửa trong repo, rồi cài lại máy ảo một lần nữa từ đầu cho tới khi chạy trơn

Không thử được trong máy ảo, chỉ kiểm tra trên máy thật: ngưỡng sạc pin 75/80, hàng phím Fn, Fn+F7 màn hình ngoài, Bluetooth và Wi-Fi thật, gập máy với caffeine, thời lượng pin.

## Cài Arch Minimal và Hyprland

Thay SSD hoặc nâng RAM là tùy chọn, không bắt buộc để cài. Đã chọn cách A (2026-11-12): kernel nằm trong root btrfs đã mã hoá như Manjaro hiện tại, để mọi snapshot chứa cả kernel lẫn module.

0. Chạy archinstall với các lựa chọn: profile Minimal; bootloader **GRUB** (không chọn systemd-boot mặc định); ổ đĩa btrfs với bố cục subvolume mặc định (@, @home, ...), nén zstd; mã hoá LUKS; phân vùng EFI giữ ở /boot như mặc định; NetworkManager; pipewire; amd-ucode; không chọn display manager (đăng nhập bằng TTY).
1. Khi archinstall hỏi có chroot vào hệ thống mới không, chọn yes. Trong chroot: cài git, clone repo dotfiles-hyprland, chạy sudo setup/arch-boot-in-root.sh (gõ YES để xác nhận, nhập mật khẩu LUKS khi được hỏi). Script đưa kernel và initramfs vào /boot trong root đã mã hoá, gắn phân vùng EFI ở /boot/efi (sửa fstab), đổi khoá LUKS sang PBKDF2 để GRUB mở được, thêm /crypto_keyfile.bin vào initramfs để chỉ nhập mật khẩu một lần, bật GRUB_ENABLE_CRYPTODISK, menu GRUB 5 giây, cài lại GRUB rồi tự kiểm tra. Chỉ khởi động lại khi mọi dòng kiểm tra báo ok. Script tự từ chối chạy nếu không phải Arch hoặc /boot không phải phân vùng EFI. Chưa thử trên máy thật: nên thử trước trong máy ảo.
2. Khởi động lại: GRUB hỏi mật khẩu LUKS (mở khoá mất vài giây), rồi màn hình TTY hỏi tài khoản và mật khẩu; đăng nhập ở TTY1 thì Hyprland tự chạy (dotfiles/.zprofile).
3. Lần đầu (từ TTY2 hoặc trước khi link dotfiles): chạy setup/setup-arch.sh. Script cài toàn bộ gói đã khai báo (78 gói, đã kiểm tra đều có trên kho chính thức hoặc AUR), bật NetworkManager, bluetooth, power-profiles-daemon, fstrim, cronie, grub-btrfsd; cài udev rule ngưỡng sạc 75/80, PAM gnome-keyring cho đăng nhập TTY, zram (bằng RAM, zstd), cấu hình Timeshift giống Manjaro (Daily 5, Weekly 3, không chụp /home), timeshift-autosnap, pacman hook kiểm tra config Hyprland, theme GTK3/GTK4/Qt, đổi shell sang zsh và chụp snapshot đầu tiên. Trước khi chạy setup/link-dotfiles.sh, clone hình nền cạnh repo dotfiles: git clone git@github-personal:diablo-harmonz/wallpapers.git ~/Documents/personal/wallpapers (repo riêng tư, cần khoá SSH personal trước; repo dotfiles không chứa hình nền). Sau đó chạy setup/link-dotfiles.sh (tự tạo symlink ~/Pictures/Wallpapers trỏ vào repo đó), rồi wallpaper restore để sinh màu.
4. Phím chức năng: cần brightnessctl, wireplumber (wpctl), playerctl (phím media) và wtype (phím Refresh gửi F5; trước đây gọi xdotool vốn chưa cài và không chạy trên Wayland). Các bind nằm trong conf/binds.lua, cú pháp hl.bind("XF86...", hl.dsp.exec_cmd("...")). Đèn nền bàn phím (Fn + Space) do firmware xử lý; thiết bị tpacpi::kbd_backlight có sẵn nếu muốn điều khiển bằng brightnessctl. Hiện trạng trên Manjaro (2026-11-11): đã dò từng phím bằng wev (lưu ý: phím đã có bind bị Hyprland giữ lại nên wev không thấy) và bind đủ hàng Fn theo bảng dưới. F1 đến F6, F9, F10, F11, F12 đã thử chạy đúng; F7 đã thử với HDMI thật (2026-11-12).

| Phím | Tên phím gửi ra | Việc |
|---|---|---|
| Fn+F7 | XF86Display | Vòng 3 bước (bin/display-toggle): lần 1 nhân bản, lần 2 mở rộng như lúc mới cắm, lần 3 tạm tắt màn hình ngoài mà không rút dây (che màn hình khi trình chiếu), rồi quay lại nhân bản. Cắm hoặc rút màn hình thì vòng bắt đầu lại từ nhân bản. Không có màn hình ngoài thì chỉ báo. Đã thử với HDMI thật |
| Fn+F8 (Mode) | Không gửi gì | Firmware tự đổi chế độ nguồn (low-power, balanced, performance); bin/powermode-notify hiện thông báo mỗi lần đổi |
| Fn+F9 (PrtSc) | Print | Chụp toàn màn hình |
| Fn+F10 | XF86SelectiveScreenshot | Chọn vùng rồi chụp |
| Fn+F11 | code:248 (NoSymbol) | Phóng toàn màn hình cửa sổ đang dùng (giống Super+F); kernel báo unhandled HKEY 0x1320 nhưng bind theo keycode vẫn chạy |
| Fn+F12 (ngôi sao) | XF86Favorites | Mở rofi |
| Phím Fn | XF86WakeUp | Không bind |

Workspace cố định theo màn hình (conf/workspaces.lua): 1 đến 5 luôn trên laptop, 6 đến 10 trên màn hình ngoài đầu tiên được cắm (cổng nào cũng được), kể cả khi trống, nên vuốt ba ngón chạy trên cả hai màn hình (vuốt chỉ chuyển giữa workspace của màn hình dưới con trỏ). Khi nhân bản hoặc tắt màn hình ngoài, 6 đến 10 dồn về laptop; mở rộng thì quay lại. workspace_swipe_create_new = false để vuốt không tạo thêm workspace 11, 12.

An toàn khi dùng màn hình ngoài: rút màn hình ngoài thì conf/monitor.lua đưa eDP-1 về bình thường và tự bật lại swaync (trình thông báo có thể sập khi màn hình đang hiện thông báo bị rút). Phím khẩn cấp Super+Ctrl+R chạy hyprctl reload, bấm được cả khi màn hình đen. Từ TTY (Ctrl+Alt+F3) phải chỉ định phiên: hyprctl -i 0 reload (thiếu -i 0 sẽ báo HYPRLAND_INSTANCE_SIGNATURE not set). Bài học: Hyprland giữ các trường của rule màn hình cũ, nên bật lại phải ghi rõ disabled = false và bỏ nhân bản phải ghi mirror = ""; thử an toàn bằng màn hình ảo hyprctl output create headless (nhưng kiểm tra trước xem có HDMI thật đang cắm không). Sau khi bỏ nhân bản, Hyprland không báo lại màn hình cho ứng dụng nên hình nền để xám; cách sửa là tắt rồi bật lại output. Laptop 16:10 và BenQ GW2790QT 16:9 khác tỉ lệ nên nhân bản luôn có viền (Hyprland vẽ viền thì nhấp nháy hình nền, BenQ vẽ viền thì đen xám); vì vậy khi nhân bản cả hai màn hình chuyển sang 1920x1080 (độ phân giải 16:9 lớn nhất cả hai cùng hỗ trợ), mở rộng thì laptop về 1920x1200. Nhấp nháy hình nền khi nhân bản là do damage tracking (Hyprland chỉ vẽ lại phần thay đổi, phần còn lại lấy từ bộ đệm cũ vốn lệch nhịp trên màn hình nhân bản); tắt rồi bật HDMI chỉ đỡ tạm thời. Sửa tận gốc: khi nhân bản đặt debug.damage_tracking = 0 (vẽ lại toàn bộ, tốn pin hơn chút), khi mở rộng, tắt hoặc rút dây thì trả về 2 (đã xác nhận hết nhấp nháy ngày 2026-11-12); BenQ mất khoảng 2 giây để sáng lại sau khi bật.

## Môi trường phát triển (làm lại trên Arch)

Thứ tự đã làm trên Manjaro ngày 2026-11-08: Git, Node, Python, Docker, Claude Code. Chụp snapshot Timeshift (--tags O) trước mỗi bước lớn. Khi thêm dòng vào file cấu hình, dùng printf với \n ở đầu để khỏi dính vào dòng cuối nếu file thiếu ký tự xuống dòng.

### 1. Git (2.56.0)

- Mặc định chung: git config --global init.defaultBranch main và git config --global core.editor nano
- Tài khoản công việc: mkdir -p ~/Documents/work, rồi ssh-keygen -t ed25519 -C "EMAIL" -f ~/.ssh/id_ed25519_work
- File ~/.ssh/config: Host github-work, HostName github.com, User git, IdentityFile ~/.ssh/id_ed25519_work, IdentitiesOnly yes; sau đó chmod 600 ~/.ssh/config
- Dán khoá công khai (cat ~/.ssh/id_ed25519_work.pub) vào GitHub, thử ssh -T git@github-work
- Danh tính theo thư mục: git config -f ~/.gitconfig-work user.name "TÊN", git config -f ~/.gitconfig-work user.email "EMAIL", git config --global includeIf."gitdir:~/Documents/work/".path "~/.gitconfig-work" (dấu / ở cuối bắt buộc; repo công việc phải nằm trong thư mục này)
- Clone bằng bí danh: git clone git@github-work:TỔ-CHỨC/REPO.git ~/Documents/work/REPO

### 2. Node (nvm 0.40.7, Node 26.13.0, npm 11.20.0)

- sudo pacman -S nvm (hoặc yay -S nvm). Không cần sửa ~/.zshrc nữa: .zshrc trong repo dotfiles-hyprland đã nạp /usr/share/nvm/init-nvm.sh (chỉ khi file có) và đã có unsetopt correct. Cài xong nvm thì mở terminal mới
- nvm install --lts, sau đó nvm alias default 26 (nếu không đặt, bí danh mặc định không trỏ tới phiên bản nào); npm đi kèm Node, không cài riêng
- Dự án cần bản khác: dùng .nvmrc hoặc trường engines, chạy nvm install rồi nvm use

### 3. Python (uv, Python 3.14.8)

- sudo pacman -S uv, rồi uv python install 3.14
- Dự án: uv venv --python 3.14, kích hoạt bằng source .venv/bin/activate, cài gói bằng uv pip install, hoặc chạy bằng uv run; không pip install thẳng vào hệ thống (Arch chặn)

### 4. Docker (Engine 29.8.2, Compose 5.6.0)

- Trên Arch mới nên tạo subvolume trước khi kéo image: sudo btrfs subvolume create /var/lib/docker; subvolume lồng không nằm trong snapshot của @, nên image không làm phình Timeshift
- Cài: sudo pacman -S docker docker-compose docker-buildx, sudo systemctl enable --now docker.service, sudo usermod -aG docker $USER
- Khởi động lại máy để nhóm docker có hiệu lực (đăng xuất rồi đăng nhập lại chưa đủ), rồi thử docker run --rm hello-world
- Nếu /var/lib/docker đã có dữ liệu: sudo systemctl stop docker.service docker.socket, sudo mv /var/lib/docker /var/lib/docker.old, sudo btrfs subvolume create /var/lib/docker, sudo systemctl start docker.service, kiểm tra rồi sudo rm -rf /var/lib/docker.old
- Lưu ý: restore snapshot hệ thống không khôi phục image và container; dữ liệu quan trọng (cơ sở dữ liệu) cần volume hoặc bản sao lưu riêng. Nhóm docker tương đương quyền root

### 5. Claude Code (2.1.319, bản native)

- curl -fsSL https://claude.ai/install.sh | bash (xem script trước bằng | less); launcher ở ~/.local/bin/claude, tự cập nhật

### 6. Ứng dụng làm việc (VS Code, Telegram, Brave, lazygit)

- Telegram: sudo pacman -S telegram-desktop
- VS Code: yay -S visual-studio-code-bin (bản của Microsoft, dùng được kho tiện ích Microsoft); khi yay hỏi cleanBuild trả lời N, chọn A để đọc PKGBUILD trước khi cài (nguồn tải phải là domain của VS Code). Sau lần mở đầu, thêm "password-store": "gnome-libsecret" vào ~/.vscode/argv.json (Hyprland không được VS Code tự nhận ra keyring)
- Cờ cho Wayland và bộ gõ: printf -- '--ozone-platform-hint=auto\n--enable-wayland-ime\n' > ~/.config/code-flags.conf (gõ tiếng Việt bằng Lotus trong VS Code đã chạy tốt trên Manjaro + Hyprland)
- Brave: yay -S brave-bin (AUR; trả lời N cho cleanBuild, chọn A để đọc PKGBUILD); cờ Wayland và bộ gõ trong ~/.config/brave-flags.conf (--ozone-platform-hint=auto, --enable-wayland-ime, chưa kiểm chứng). Khi test frontend, Brave Shields có thể chặn tài nguyên, tắt Shields cho riêng site đó; nên có thêm Chromium (sudo pacman -S chromium) và Firefox để kiểm tra
- lazygit: sudo pacman -S lazygit, chạy lazygit trong repo; dùng đúng danh tính theo thư mục và bí danh SSH; alias tùy chọn alias lg='lazygit'; push sẽ treo hỏi passphrase nếu chưa nạp khoá vào ssh-agent
- Snapshot mốc sau bước này: sudo timeshift --create --comments "Đã cài VS Code, Telegram, Brave, lazygit" --tags O
- LibreOffice (làm sau, khi cài Arch thuần): có trong repo chính thức, chạy được trên Hyprland. Cài sudo pacman -S libreoffice-fresh (bản mới nhất) hoặc libreoffice-still (ổn định hơn), chọn một. Giao diện tiếng Việt: libreoffice-fresh-vi; chính tả tiếng Việt: hunspell-vi (tên gói chưa kiểm chứng). Gõ tiếng Việt qua fcitx5 trong LibreOffice chưa thử, cần kiểm tra sau khi cài.

## Công cụ cần cài trên Arch

Cấu hình và cách dùng. zram, btop, lm_sensors, smartmontools, upower, Timeshift và các gói chụp, quay màn hình đã nằm trong setup/setup-arch.sh.

- zram (swap nén trong RAM): Manjaro bật sẵn, Arch phải tự bật. Đã tự động: setup/install-system-files.sh chép setup/system/zram-generator.conf ([zram0], zram-size = ram, compression-algorithm = zstd; đổi từ ram / 2 ngày 2026-11-13 vì zram đầy khi chạy test Playwright làm máy giật) rồi bật, kèm sysctl cho zram trong setup/system/99-vm-zram.conf (swappiness 180, page-cluster 0, watermark). Kích thước mới chỉ có hiệu lực sau khi khởi động lại. Kiểm tra bằng zramctl và swapon --show. Chưa thử trên Arch thật.
- Kích thước zram chỉ là mức trần: trên Manjaro nó tự co khoảng một nửa RAM (5,7 GiB khi RAM 11 GiB), RAM thật chiếm khoảng một phần tư nhờ nén.
- Giám sát tài nguyên: btop xem CPU, RAM, đĩa, mạng trên một màn hình; sắp xếp theo RAM: bấm f rồi chọn mem (htop đã gỡ 2026-11-15, btop thay). Lệnh có sẵn không cần cài: free -h, vmstat 1, cat /proc/pressure/memory. Trên Waybar, rê chuột vào mũi tên bên trái để xem CPU/RAM, bấm để mở syslive.
- Sau khi dựng xong Arch + Hyprland, chạy sysreport lúc rảnh để có số RAM thật so với Manjaro.
- Kiểm tra nhanh tình trạng máy: sudo smartctl -H -A /dev/nvme0n1 (SSD), upower -i $(upower -e | grep BAT) (pin), systemctl --failed (dịch vụ lỗi), journalctl -b -p err (lỗi hệ thống), docker stats --no-stream (Docker). Hoặc chạy sysreport để có tất cả một lần.
- Tắt máy đúng cách: systemctl poweroff hoặc systemctl reboot; tránh giữ nút nguồn để không làm tăng Unsafe Shutdowns của SSD. Khi máy đơ: Ctrl+Alt+F3 rồi pkill Hyprland hoặc systemctl poweroff.
- Chụp và quay màn hình: grim, slurp, satty, wf-recorder, wl-clipboard (đã trong setup-arch.sh). Script screenshot (area, full, edit) lưu ảnh vào ~/Pictures/Screenshots, chép vào clipboard và hiện preview nhỏ ở góc dưới bên phải (kéo thả vào ứng dụng, bấm để sửa bằng satty, nút xoá); screenrec (area, full, thêm audio để thu tiếng) lưu video .mp4 vào ~/Videos/Recordings, bấm lại phím tắt để dừng. Phím tắt ở bảng dưới.
- Đổi video sang GIF: ffmpeg -i ~/Videos/Recordings/rec.mp4 -vf "fps=12,scale=720:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" ~/Videos/rec.gif (giảm fps hoặc scale nếu file nặng). Quay kèm webcam hoặc phát trực tiếp thì dùng obs-studio, cần xdg-desktop-portal-hyprland và pipewire.
- Xem và tải video: sudo pacman -S mpv yt-dlp. Phát: mpv <URL> (mpv tự gọi yt-dlp) hoặc mpv ~/Videos/Recordings/rec.mp4. Tải video chất lượng tốt nhất: yt-dlp -f "bv*+ba/b" <URL>; chỉ lấy âm thanh: yt-dlp -x --audio-format mp3 <URL> (cần ffmpeg). Giải mã bằng phần cứng: thêm hwdec=auto vào ~/.config/mpv/mpv.conf (card AMD có thể cần driver VA-API của Mesa, tên gói chưa kiểm chứng). yt-dlp hay lỗi khi trang đích đổi, cập nhật bằng sudo pacman -Syu, không dùng yt-dlp -U. Chỉ tải nội dung được phép, dùng cá nhân. Chưa thử trên máy.

| Phím tắt | Việc | Lưu vào |
|---|---|---|
| Print (Fn+F9) | Chụp toàn màn hình, chép vào clipboard, hiện preview | ~/Pictures/Screenshots |
| Fn+F10 hoặc Shift + Print | Chọn vùng rồi chụp, chép vào clipboard, hiện preview | ~/Pictures/Screenshots |
| Super + Print | Chọn vùng rồi mở satty để chú thích | Lưu hoặc chép từ satty |
| Super + Shift + R | Bắt đầu hoặc dừng quay vùng chọn | ~/Videos/Recordings |
| Super + Alt + R | Bắt đầu hoặc dừng quay toàn màn hình | ~/Videos/Recordings |

## Ghi log tài nguyên liên tục (atop, sysstat) để bắt lúc máy giật

Ghi chú 2026-11-10: phần này chỉ áp dụng cho Manjaro (chạy đến hết hạn đổi trả). Không cài atop và sysstat trên Arch.

- atop: chạy nền, ghi trạng thái hệ thống theo chu kỳ vào /var/log/atop, cho phép xem lại đúng thời điểm bị giật để thấy tiến trình nào ăn RAM, CPU, đĩa. Cài: sudo pacman -S atop, bật: sudo systemctl enable --now atop.
- Cấu hình atop nằm ở /etc/default/atop (đã xác nhận trên Manjaro): LOGINTERVAL là chu kỳ ghi tính bằng giây (mặc định 600, quá thưa), LOGGENERATIONS là số ngày giữ log (mặc định 28), LOGPATH là thư mục log. Đặt chu kỳ 60 giây: sudo sed -i 's/^LOGINTERVAL=600$/LOGINTERVAL=60/' /etc/default/atop, rồi sudo systemctl restart atop. Kiểm tra bằng systemctl status atop, dòng atop -w ... phải kết thúc bằng 60.
- Xem lại: atop -r, bấm t (tiến) và T (lùi) để đi theo thời gian, bấm m để xem theo bộ nhớ. Sau một ngày chạy du -sh /var/log/atop; nếu nặng thì hạ LOGGENERATIONS xuống khoảng 7 (sửa bằng sed tương tự, rồi restart atop).
- sysstat (lệnh sar): ghi số liệu tổng hợp theo thời gian. Cài: sudo pacman -S sysstat. Trên Manjaro có bảy unit; cần bật bốn cái: sudo systemctl enable --now sysstat.service sysstat-collect.timer sysstat-rotate.timer sysstat-summary.timer. Kiểm tra: systemctl list-timers 'sysstat*'. Xem RAM: sar -r, xem swap/paging: sar -B. Chu kỳ ghi mặc định khoảng 10 phút.
- Bổ trợ: PSI (cat /proc/pressure/memory, atop/sar không ghi), journalctl -k xem log kernel nếu từng chạm giới hạn RAM. btop chỉ xem trực tiếp, không lưu lịch sử. Netdata, Prometheus + Grafana nặng, không cần cho máy cá nhân.
- Trạng thái: đã cài và chạy trên Manjaro (atop chu kỳ 600 giây; ở 60 giây log từng nặng 36 MB cho khoảng 5 giờ, ước khoảng 170 MB mỗi ngày). Đã xác nhận (2026-11-10) sar đã có dữ liệu, và chưa thử trên Arch thật.

## Đã chuẩn bị sẵn cho Arch

Làm trên Manjaro ngày 2026-11-10 đến 11-12; dùng lại khi cài Arch.

- Symlink: mọi thư mục trong dotfiles/.config (hypr, waybar, rofi, wezterm, fcitx5, matugen, swaync, zsh, ...), ~/.zshrc, ~/.zprofile và các script trong bin/ (vào ~/.local/bin) trỏ vào repo; sửa file xong git status thấy ngay, rồi commit và push. Cài Arch: clone repo dotfiles-hyprland rồi chạy setup/link-dotfiles.sh, script tự tạo lại toàn bộ symlink và đổi tên file cũ thành *.bak-<thời gian> trước khi link. Các file màu do Matugen sinh ra không nằm trong git; chạy wallpaper restore một lần sau khi link. Clone bằng https chỉ chạy được nếu repo công khai, chưa xác nhận; chưa thử trên máy sạch.
- Pacman hook kiểm tra config Hyprland sau mỗi lần cài hoặc nâng cấp Hyprland: setup/install-pacman-hooks.sh (cần sudo, setup-arch.sh tự gọi) chép hook vào /etc/pacman.d/hooks và script vào /usr/local/lib/dotfiles-hyprland (thuộc root, không chạy file trong home). Nếu config lỗi, pacman in WARNING kèm dòng lỗi; sửa trước khi đăng xuất hoặc khôi phục snapshot Timeshift. Trước khi nâng cấp Hyprland lên bản chính (0.57, ...) nên đọc release notes; không giữ cố định phiên bản bằng IgnorePkg (Arch không hỗ trợ cập nhật một phần). Gói launcher trên Arch là rofi (bản 2.0 đã gộp rofi-wayland).
- Cấu hình Hyprland (Lua) trong dotfiles/.config/hypr/conf: monitor, workspaces, autostart, cursor, environments, input, general, decoration, animations, layouts, gestures, misc, windowrules, binds. Kiểm tra bằng Hyprland --verify-config --config ~/.config/hypr/hyprland.lua; thử màn hình bằng hyprctl output create headless mà không cần cắm dây.
- Ngưỡng sạc pin 75/80: không dùng phần mềm riêng (không dùng TLP vì xung đột với power-profiles-daemon). Dịch vụ battery-charge-threshold.service đặt 75/80 một lần lúc khởi động (bản udev rule đầu tiên tự kích hoạt lặp vô tận, làm treo Waybar ngày 2026-11-12, đã bỏ). Nút 🍃/⚡ trên Waybar (bin/battery-mode) chuyển giữa bảo vệ pin 75–80 % và sạc đầy 100 %, hỏi mật khẩu mỗi lần qua polkit (script root /usr/local/lib/dotfiles-hyprland/battery-threshold); khởi động lại máy luôn về 75–80 %.
- earlyoom: khi RAM khả dụng dưới 4 % và zram trống dưới 5 % thì tắt tiến trình lớn nhất, ưu tiên trình duyệt (Brave, Chrome, Firefox) và tiến trình test (chrome-headless, node, ffmpeg, playwright); không bao giờ tắt Hyprland, Waybar, WezTerm, VS Code. Cấu hình setup/system/earlyoom. Đợt khựng lúc chạy test server (2026-11-12 15:47) là áp lực bộ nhớ chứ chưa cạn, nên cần giảm worker và tắt quay video của Playwright.
- Mốc sức khoẻ pin (2026-11-10): dung lượng đầy 57,55 Wh trên thiết kế 57 Wh, 4 chu kỳ sạc; chạy sysreport định kỳ rồi so energy-full với energy-full-design để theo dõi.
- BIOS: Config, Display, UMA Frame buffer Size đã đổi từ Auto (4 GiB) xuống 1G; RAM tổng hiển thị tăng từ 11 lên 14 GiB. Thiết lập nằm ở BIOS nên thường còn nguyên khi cài Arch (trừ khi BIOS bị reset).
