# Cập nhật hệ thống

Cập nhật khoảng **mỗi tuần một lần**. Chỉ cần nhớ **một lệnh**, gõ trong terminal (kitty):

```
sysupdate
```

Lệnh này dẫn bạn đi qua 6 bước, hỏi trước mỗi việc làm thay đổi máy, ghi lại toàn bộ quá
trình vào file log và cuối cùng tóm tắt việc cần làm tiếp. Phần dưới giải thích từng bước,
các file liên quan và cách xử lý khi có sự cố.

---

## Quy tắc: cập nhật cuối tuần, trong tuần chỉ làm việc

Phần tuỳ biến của máy này chủ yếu là **giao diện** (Waybar, Control Center, thông báo, màn
khoá, menu nguồn, rmpc, màu Matugen…); phần lõi (kernel, mạng, âm thanh, ổ đĩa mã hoá) gần
như mặc định. Hỏng giao diện thì xấu hoặc thiếu tiện ích, **không chặn công việc**, nên sửa
cuối tuần là được.

1. **Chỉ chạy `sysupdate` vào tối thứ Sáu hoặc cuối tuần.** Cấu hình không tự hỏng: gần như
   mọi lỗi xuất hiện ngay sau khi cập nhật. Cập nhật lúc rảnh = lỗi (nếu có) đến lúc rảnh.
2. **Trong tuần không cập nhật**, trừ khi có tin bảo mật khẩn trên archlinux.org.
3. **Lỗi chặn công việc giữa tuần → quay lại snapshot, đừng sửa vội:**
   `sudo timeshift --restore`, chọn bản trước lần cập nhật (vài phút). Cuối tuần cập nhật
   lại và sửa cho đúng (xem mục **Sự cố**).

Lỗi **chặn công việc** và cách tạm để làm việc tiếp:

| Sự cố | Cách tạm |
|---|---|
| Không vào được desktop (Hyprland) | Hook đã báo trước khi đăng xuất. Đã lỡ: Ctrl+Alt+F3, `sudo timeshift --restore` |
| Không khởi động được (kernel, GRUB) | Menu GRUB → "… Linux snapshots" → vào máy → `sudo timeshift --restore` |
| Không gõ được tiếng Việt | Chuyển sang Bamboo (dự phòng), hoặc `systemctl restart fcitx5-lotus-server@$USER` |
| Mất Wi-Fi / mạng | Bấm icon Wi-Fi (nmtui), hoặc cắm dây LAN |
| Tai nghe Bluetooth không kết nối | Mở bluetui từ Control Center, hoặc dùng loa laptop |

Để được tới cuối tuần: Waybar, Control Center, thông báo, màn khoá xấu đi (vẫn mở khoá
được), màu không theo hình nền, rmpc / yt-x / cava / btop, thẻ xem trước ảnh chụp, đĩa than…

---

## Chuẩn bị (chỉ làm một lần)

| Việc | Lệnh | Để làm gì |
|---|---|---|
| Cài pacman-contrib | `sudo pacman -S pacman-contrib` | Có `checkupdates` (xem gói sắp cập nhật mà không đụng vào máy) và `pacdiff` (gộp file `.pacnew`) |
| Cài 3 pacman hook | `~/Documents/personal/dotfiles-hyprland/setup/install-pacman-hooks.sh` | Sau khi cập nhật Hyprland / rmpc / Matugen, tự kiểm tra cấu hình và báo lỗi (đã cài 2026-11-15) |

Trên máy cài mới, `setup/setup-arch.sh` làm cả hai việc này.

---

## Từng bước của `sysupdate`

Khi script hỏi `[y/N]`: gõ **y** rồi Enter để đồng ý; chỉ Enter (hoặc n) là **không**.
Bấm **Ctrl + C** bất cứ lúc nào trước bước 5 để dừng, máy chưa bị thay đổi gì.

### Bước 1 · Arch news (tin của Arch)

- Script in các tin mới trên archlinux.org kể từ lần cập nhật trước.
- **Không có tin** → `✔ No new Arch news` → tự sang bước 2.
- **Có tin** → đọc kỹ. Thỉnh thoảng Arch yêu cầu làm một việc bằng tay *trước* khi cập
  nhật (gọi là "manual intervention"), tin sẽ ghi rõ lệnh. Làm xong (hoặc nếu tin chỉ để
  biết) thì gõ **y** để tiếp tục. Không chắc → gõ Enter để dừng, hỏi rồi chạy lại sau.

### Bước 2 · What will change (những gì sẽ thay đổi)

- Đầu tiên script **đo tốc độ mirror** (máy chủ tải gói) đứng đầu danh sách:
  - `✔ Mirror …: 2500 KB/s` → mirror ổn, đi tiếp.
  - `! Mirror … is slow` hoặc `does not answer` (dưới 200 KB/s) → script tự chọn lại 5
    mirror nhanh nhất (hỏi mật khẩu), đo lại rồi báo `Now using …`. Xem mục **Mirrors** bên
    dưới.
- Script hỏi danh sách gói có bản mới (gói chính thức + gói AUR), **không cài gì cả**.
- Trong lúc chờ mạng, dòng đang chạy có **vòng xoay, số giây đã chờ** và số MB đã tải, ví
  dụ `⠹ Checking official packages… (12s, 3.3 MB downloaded)`. Số giây vẫn tăng = đang chạy,
  không phải treo. Quá 30 giây dòng đó nhắc xem mục **Mirrors**.
- `✔ Everything is up to date` → không có gì để cập nhật, script dừng ở đây.
- Dòng **Worth knowing** liệt kê các gói quan trọng:

| Dòng hiện ra | Nghĩa | Bạn làm gì |
|---|---|---|
| `kernel linux… → …` | Kernel mới | Sau khi cập nhật phải khởi động lại máy |
| `Hyprland 0.56 → 0.57: new release` | Hyprland lên bản lớn | Mở link, đọc phần "Breaking changes" trước khi tiếp tục |
| `Hyprland 0.56.2 → 0.56.3` | Bản vá nhỏ | Không cần làm gì, đăng xuất / đăng nhập sau khi cập nhật |
| `mesa`, `systemd`, `glibc` | Gói lõi | Không cần làm gì thêm |
| `rmpc`, `matugen` | Có hook kiểm tra | Xem kết quả kiểm tra ở bước 6 |

- Câu hỏi `Show the full list?` → **y** nếu muốn xem toàn bộ danh sách, Enter để bỏ qua.
- Dòng **Leftovers: …** (nếu có): gói AUR có bản mới nhưng chỉ được cài làm phụ thuộc cho
  một app cũ, nay **không gói nào cần** và **đã bị gỡ khỏi kho chính thức** (thường là thư
  viện KDE còn sót từ Manjaro KDE, ví dụ `kirigami2`). Cập nhật chúng nghĩa là yay tải mã
  nguồn về tự build, tốn thời gian mà không để làm gì. Câu hỏi `Remove them now instead of
  updating them?` → **y** để gỡ (nhập mật khẩu, rồi **Enter** khi pacman hỏi xác nhận).

### Bước 3 · Power (nguồn điện)

- Đang cắm sạc → `✔ Plugged in`.
- Đang chạy pin → cảnh báo. Mất điện giữa chừng khi đang cài có thể làm hỏng hệ thống, nên
  **cắm sạc rồi chạy lại** (Enter để dừng).

### Bước 4 · Extra snapshot (snapshot thêm)

- Trước mỗi lần cập nhật, **timeshift-autosnap** tự chụp một snapshot, nhưng chỉ giữ **3 bản
  gần nhất** (bản cũ bị xoá dần).
- Với **cập nhật lớn** (kernel hoặc Hyprland lên bản lớn), script đề nghị chụp thêm một
  snapshot **thủ công** (tag O): bản này được giữ đến khi bạn tự xoá. Gõ **y**, nhập mật khẩu,
  đợi vài giây.
- Cập nhật nhỏ → `✔ … the automatic snapshot is enough` → bỏ qua.

### Bước 5 · Update (cập nhật)

Trước câu hỏi, script in sẵn bảng **các câu yay sẽ hỏi và bấm gì**. Quy tắc chung: dòng
**dừng lại, con trỏ nhấp nháy ở cuối** là máy đang **chờ bạn trả lời**; chữ **đang chạy liên
tục** (tải, build, cài) thì chỉ cần chờ.

Script hỏi `Start the update?` → **y**. Từ đây là `yay -Syu` chạy thật:

1. Nhập **mật khẩu** khi được hỏi (gõ không hiện gì, gõ xong Enter).
2. Hai menu của yay **được trả lời sẵn** (`--answerupgrade None --answerclean None`), nên
   không còn hiện:
   - `Packages to exclude` (loại gói khỏi đợt cập nhật): luôn là *không loại gói nào*
     (loại gói = cập nhật nửa vời, dễ hỏng máy). Ngày 2026-11-20 câu này làm tưởng script
     đứng im, vì nó chỉ là một dòng `==>` chờ Enter.
   - `Packages to cleanBuild?`: luôn là *không*, giữ bộ nhớ build cho lần sau.
3. `Proceed with installation? [Y/n]` → **Enter** (= Yes).
4. Với gói **AUR** (ví dụ yt-x, fcitx5-lotus, visual-studio-code-bin), yay hỏi
   `Diffs to show?` → **Enter** để bỏ qua; hoặc gõ **A** (all) để xem thay đổi, đọc lướt xem
   nguồn tải có lạ không, bấm **q** để thoát phần xem.
5. Trước khi cài, dòng `timeshift-autosnap` hiện ra: snapshot tự động đang được chụp.
6. Sau khi cài, có thể thấy:
   - `Checking Hyprland configs…` / `Checking rmpc configs…` / `Checking Matugen templates…`:
     ba hook kiểm tra cấu hình. `:: … OK` là ổn.
   - `warning: /etc/… installed as /etc/….pacnew`: xem bước 6.

Không được tắt máy hay đóng terminal trong lúc bước này đang chạy.

### Bước 6 · Summary (tóm tắt)

Script đọc lại toàn bộ log và chỉ ra:

| Dòng | Nghĩa | Làm gì |
|---|---|---|
| `✔ Packages updated` | Cập nhật xong | |
| `✔ Hyprland / rmpc / Matugen config checked: OK` | Cấu hình hợp với bản mới | |
| `✘ A config check reported a problem` | Một hook báo lỗi, kèm file và dòng | Xem mục **Sự cố** bên dưới |
| `! New default config files to merge (.pacnew)` | Có file cấu hình hệ thống mới | Xem mục **File .pacnew** |
| `! The kernel was updated: a reboot is needed` | Kernel mới | Trả lời câu hỏi reboot ở cuối (hoặc sau: `systemctl reboot`) |
| `! Hyprland was updated: log out and in` | Hyprland mới | SUPER + M rồi đăng nhập lại |
| `✔ No reboot needed` | Không cần làm gì | |

Cuối bước 6 luôn có dòng **`━━ Done. sysupdate has finished; nothing is running any more.`**
(hoặc `Finished with an error` khi yay lỗi): thấy dòng này là xong hẳn, không còn gì chạy.
Ngay sau đó là câu hỏi cuối:

- Kernel vừa cập nhật → `Reboot now? … [Y/n]`: **Enter** = khởi động lại (lưu việc ở cửa sổ
  khác trước), **n** = để sau.
- Không cần → `Reboot now anyway? [y/N]`: **Enter** = không.
- Chọn khởi động lại thì còn 5 giây để **Ctrl + C** huỷ. Không có bàn phím (chạy không qua
  terminal) thì không bao giờ tự khởi động lại.

Cuối cùng thử nhanh: Waybar, Control Center, đổi hình nền một lần (SUPER + W, để tạo lại
màu), mở rmpc. Thêm tuỳ gói vừa cập nhật:

- **fcitx5-lotus**: bộ gõ đang chạy vẫn là bản cũ trong bộ nhớ cho tới khi khởi động lại.
  Đăng xuất / đăng nhập, hoặc ngay: `sudo systemctl restart fcitx5-lotus-server@$USER && fcitx5 -rd`.
  Rồi gõ thử `w` → ư, `ww` → w (W2U=Everywhere trong `dotfiles/.config/fcitx5/conf/lotus.conf`).
- **firefox** lên bản chính mới (ví dụ 159 → 160): mở lại, xem thanh tab dọc và thanh địa chỉ
  (FF Ultima là CSS, có thể lệch; lỗi giao diện, để cuối tuần sửa).

### Dọn gói mồ côi (tuỳ chọn)

Gói mồ côi = cài làm phụ thuộc nhưng nay không gói nào cần (`pacman -Qdtq` liệt kê).
Script chỉ hỏi gỡ những gói mồ côi có bản AUR mới (dòng **Leftovers** ở bước 2); số còn lại
gỡ tay sau khi cập nhật:

```
sudo pacman -Rns $(pacman -Qdtq)
```

Đọc danh sách pacman in ra rồi **y**. Snapshot autosnap trước lần cập nhật vẫn chứa các gói
này, lỡ gỡ nhầm thì khôi phục được. Lần dọn đầu (2026-11-18) gỡ 16 gói (~76 MB): thư viện KDE và Qt5
cũ, ffmpeg4.4, flashrom, meson, …

---

## Các file liên quan

| File | Là gì |
|---|---|
| `bin/sysupdate` (→ `~/.local/bin/sysupdate`) | Lệnh cập nhật có hướng dẫn |
| `~/.local/state/sysupdate/<ngày>.log` | Log mỗi lần cập nhật (toàn bộ những gì hiện trên màn hình) |
| `/etc/pacman.d/hooks/*-verify-config.hook` | 3 hook: báo pacman chạy kiểm tra sau khi cập nhật hyprland / rmpc / matugen |
| `/usr/local/lib/dotfiles-hyprland/*-verify-config` | Script kiểm tra mà hook gọi (bản gốc: `setup/pacman-hooks/` trong repo; sửa xong chạy lại `setup/install-pacman-hooks.sh`) |
| `/usr/share/libalpm/hooks/00-timeshift-autosnap.hook` | Hook chụp snapshot trước mỗi lần cập nhật (của gói timeshift-autosnap) |
| `/etc/timeshift-autosnap.conf` | Cấu hình autosnap: `maxSnapshots=3` (giữ 3 bản) |
| `sudo timeshift --list` | Xem các snapshot đang có (autosnap: tag O+, thủ công: tag O) |
| `*.pacnew` trong `/etc` | Bản cấu hình mặc định mới của một gói, đặt cạnh file bạn đã sửa |

---

## Sự cố

### Hook báo lỗi Hyprland (`==> WARNING: Hyprland … reports problems`)

- Hyprland **đang chạy** vẫn là bản cũ, nên chưa có gì hỏng. Nhưng **lần đăng nhập sau** sẽ
  dùng bản mới và có thể màn hình đen.
- **Đừng đăng xuất.** Gửi nội dung WARNING cho Claude để sửa cấu hình trong repo, hoặc tự sửa
  file và dòng được nêu.
- Kiểm tra lại bằng tay: `Hyprland --verify-config --config ~/.config/hypr/hyprland.lua`
  (phải in `config ok`).

### Hook báo lỗi rmpc hoặc Matugen

- Không gấp: nhạc vẫn phát (MPD), màu hiện tại vẫn giữ. rmpc mở với giao diện mặc định;
  Matugen sẽ lỗi ở lần đổi hình nền tới.
- Sửa file được nêu (`dotfiles/.config/rmpc/…` hoặc `dotfiles/.config/matugen/templates/…`),
  rồi kiểm tra lại:
  - `~/Documents/personal/dotfiles-hyprland/setup/pacman-hooks/rmpc-verify-config`
  - `~/Documents/personal/dotfiles-hyprland/setup/pacman-hooks/matugen-verify-config`

### File .pacnew

Gói mới có cấu hình mặc định khác, nhưng bạn (hoặc setup) đã sửa file cũ, nên pacman không
ghi đè mà để bản mới cạnh đó với đuôi `.pacnew`.

```
sudo DIFFPROG="nvim -d" pacdiff
```

Với từng file, pacdiff hỏi:
- **v** (view): mở hai bản cạnh nhau trong nvim để so. Thoát nvim: `:qa`.
- **o** (overwrite): dùng bản mới, bỏ bản cũ. Chỉ chọn khi bạn chưa sửa gì quan trọng trong file đó.
- **r** (remove): giữ bản cũ của bạn, xoá `.pacnew`. Thường đúng với file repo này đã cài
  (`/etc/default/earlyoom`, `/etc/nftables.conf`, `/etc/security/faillock.conf`, …).
- **s** (skip): để sau.

Không chắc → **s**, rồi hỏi.

### yay dừng giữa chừng (lỗi mạng, xung đột gói)

- Nếu lỗi xảy ra **trước** khi pacman bắt đầu cài (`(1/…) upgrading …` chưa hiện): máy chưa
  đổi gì, chạy lại `sysupdate` sau.
- Lỗi khoá (`signature … is unknown trust`): `sudo pacman -Sy archlinux-keyring` rồi chạy lại.
- Lỗi khác: gửi phần cuối log (`~/.local/state/sysupdate/<ngày>.log`) cho Claude.

### Mirrors (sysupdate đứng yên rất lâu ở bước 2)

**Chuyện đã xảy ra (2026-11-20):** bước 2 đứng ở `Checking for updates…` cả buổi, không báo
gì. Thật ra không treo: `checkupdates` đang tải danh sách gói `extra.db` (~9,5 MB) từ mirror
đầu danh sách (`ftp.yz.yamagata-u.ac.jp`, Nhật Bản) với tốc độ **~12 KB/s**, trong khi
`mirrors.manjaro.org` cho ~2,7 MB/s. Mirror chậm thì bước cài (bước 5) cũng chậm như vậy.

**Bây giờ `sysupdate` tự xử lý:** đo mirror đầu danh sách ở đầu bước 2 (tải thử 2 MB, tối đa
8 giây, lần đầu chậm thì đo lại một lần vì lần đầu còn mất thời gian DNS / TLS); dưới 200 KB/s
thì chọn lại mirror. Các bước mạng đều có vòng xoay và số giây, nên chậm mà vẫn chạy thì thấy
ngay.

**Làm tay khi cần:**

- Xem mirror đang dùng: `grep -m3 '^Server' /etc/pacman.d/mirrorlist` (dòng đầu được dùng
  trước).
- Đo thử một mirror (số byte/giây):
  `curl -s -o /dev/null -r 0-2097151 -w '%{speed_download}\n' <URL mirror>/extra/x86_64/extra.db`
- **Manjaro:** `sudo pacman-mirrors --fasttrack 5` (đo và giữ 5 mirror nhanh nhất), rồi
  chạy lại `sysupdate`.
- **Arch:** cài `sudo pacman -S reflector`, rồi
  `sudo reflector --protocol https --latest 20 --sort rate --number 5 --save /etc/pacman.d/mirrorlist`.
  Không có reflector thì `sysupdate` chỉ cảnh báo và chạy tiếp với mirror cũ.
- Đang kẹt giữa chừng ở bước 2: **Ctrl + C** an toàn (bước 2 chưa đổi gì trên máy), đổi
  mirror rồi chạy lại.

### Hỏng nặng: không vào được desktop

1. **Còn vào được TTY:** Ctrl + Alt + F3, đăng nhập, chạy `sudo timeshift --restore`, chọn
   snapshot `Before update …` hoặc bản autosnap trước lần cập nhật (cột Tags `O+`/`O`), xác
   nhận, máy tự khởi động lại.
2. **Không khởi động được:** khởi động lại, trong menu GRUB chọn
   **"Arch Linux snapshots"** (Manjaro: "Manjaro Linux snapshots"), chọn snapshot trước khi
   cập nhật để vào máy, rồi chạy `sudo timeshift --restore` để khôi phục hẳn.

---

## Làm tay (không dùng sysupdate)

Đúng thứ tự `sysupdate` làm, nếu cần:

```
yay -Pw                      # 1. tin Arch
checkupdates; yay -Qua       # 2. gói sắp cập nhật (chính thức; AUR)
sudo timeshift --create --comments "Before update" --tags O   # 4. snapshot thủ công (tuỳ)
yay -Syu                     # 5. cập nhật (không bao giờ cập nhật lẻ một gói)
sudo DIFFPROG="nvim -d" pacdiff   # 6. gộp .pacnew nếu có
systemctl reboot             #    nếu kernel đổi
```

---

## Cập nhật dotfiles (repo này) trên máy khác

Mọi cấu hình là symlink trỏ vào repo, nên sửa ở máy này, push, rồi ở máy kia:

```
git -C ~/Documents/personal/dotfiles-hyprland pull
```

- Sửa file đã có (config, script): xong ngay, app nào đọc lại config là thấy (Hyprland tự nạp lại; Waybar: SUPER + SHIFT + B).
- Repo có **file hoặc thư mục mới** (script mới trong `bin/`, thư mục mới trong `dotfiles/.config/`): chạy thêm `setup/link-dotfiles.sh` để tạo symlink cho nó. Chạy lại bao nhiêu lần cũng an toàn (2026-11-20: `bin/waybar-launch` mới, chỉ pull thì Hyprland gọi script chưa có).
- `setup-arch.sh` có **gói mới**: cài riêng gói đó (`sudo pacman -S …` hoặc `yay -S …`), hoặc chạy lại `setup/setup-arch.sh` (bỏ qua gói đã có).

## Plugin Neovim (không nằm trong yay)

Plugin cài bằng `vim.pack` không được `yay -Syu` cập nhật. Làm riêng, cũng vào cuối tuần:

1. Trong Neovim: `:lua vim.pack.update()`. Một trang mới liệt kê các thay đổi của từng plugin.
2. Đọc qua, rồi `:w` để cập nhật, hoặc `:q` để huỷ.
3. Thoát và mở lại Neovim, dùng thử.
4. Ổn thì commit `dotfiles/.config/nvim/nvim-pack-lock.json`. Hỏng thì quay về bản cũ:
   `git -C ~/Documents/personal/dotfiles-hyprland checkout -- dotfiles/.config/nvim/nvim-pack-lock.json`,
   rồi trong Neovim `:lua vim.pack.update(nil, { target = "lockfile" })`.
