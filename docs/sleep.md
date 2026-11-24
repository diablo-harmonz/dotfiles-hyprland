# Gập máy và chế độ ngủ

Ghi chú cho ThinkPad T14 Gen 6 (AMD). Gập máy là máy **ngủ nhẹ** (`s2idle`, xem
`cat /sys/power/mem_sleep`), mở ra dùng ngay. Gập máy khi đang cắm màn hình ngoài thì không
ngủ (xem `bin/display-toggle`).

**Ngủ đông đang tắt từ 2026-11-25** vì GPU không thức dậy được sau ngủ đông, xem mục
**Ngủ đông: tạm tắt** ngay dưới. Phần cài đặt ngủ đông vẫn còn (swapfile 20 GB, `resume=`,
`setup/enable-hibernate.sh`), chỉ không còn tự chuyển sang ngủ đông nữa.

---

## Ngủ đông: tạm tắt (2026-11-25)

**Đừng dùng ngủ đông** (`systemctl hibernate`, nút Hibernate ở menu nguồn) cho tới khi có
kernel hoặc `linux-firmware` sửa lỗi dưới đây.

### Lỗi 1: GPU AMD không khôi phục được sau ngủ đông (nghiêm trọng)

- 2026-11-24: thử tay `systemctl hibernate` một lần, thành công, cửa sổ còn nguyên.
- 2026-11-25 06:16: thử lại `systemctl hibernate`. Ngủ đông và nạp lại RAM đều thành công,
  nhưng GPU (`amdgpu`, PCI `c4:00.0`, device `0x1114`, khối `gfx_v11_0`) **không khởi động
  lại được**:
  ```
  amdgpu: MES failed to respond to msg=SET_HW_RSRC_1
  [drm:mes_v11_0_hw_init [amdgpu]] *ERROR* failed mes_v11_0_set_hw_resources_1, r=-110
  amdgpu: resume of IP block <gfx_v11_0> failed -110
  amdgpu: PM: dpm_run_callback(): pci_pm_restore returns -110
  ```
  Sau đó driver reset GPU nhiều lần (`ring sdma0 timeout`, `MODE2 reset`, `Ring comp_1.2.0
  reset failed`), Hyprland hỏng, phải khởi động lại máy.
- Lúc đó: kernel `linux 7.3.5.arch1-1`, `linux-firmware 20261019-1`, `mesa 26.3.1`,
  `hyprland 0.57.2`. Không có bản cập nhật kernel hay firmware nào đang chờ.
- Ngủ nhẹ (`s2idle`) **không** bị lỗi này: gập máy qua đêm 2026-11-24, mở ra bình thường.
- Lỗi lúc được lúc không (11-24 thành công, 11-25 hỏng), nên một lần thử thành công chưa đủ
  để bật lại.

Đã đổi (2026-11-25):
- `setup/system/logind.conf.d/lid.conf`: `HandleLidSwitch=suspend` (trước là
  `suspend-then-hibernate`). Cài lên máy bằng `sudo install -m 644` vào
  `/etc/systemd/logind.conf.d/`, rồi `sudo systemctl kill -s HUP systemd-logind`.
- `hypr/hypridle.conf`: bước 30 phút khi chạy pin gọi `systemctl suspend` (trước là
  `suspend-then-hibernate`). Cần khởi động lại hypridle hoặc đăng nhập lại.
- Giữ nguyên: swapfile, `resume=` trong GRUB, `sleep.conf.d/hibernate.conf`
  (`HibernateDelaySec` chỉ có tác dụng với `suspend-then-hibernate`).

Bật lại khi nào: khi có `linux` hoặc `linux-firmware` mới, đọc changelog tìm `MES`,
`gfx11`/`gfx_v11`, `hibernate`/`S4`, `pci_pm_restore`. Nếu có, lưu hết việc đang làm rồi thử
`systemctl hibernate` **vài lần**, mỗi lần xem
`journalctl -b -1 -k | grep -iE 'amdgpu|hibernat'` (nếu không khởi động lại thì `-b 0`).
Ổn thì đổi lại hai chỗ trên và nhớ sửa luôn Lỗi 2.

### Lỗi 2: zram làm ngủ đông thất bại khi RAM đầy

- Đêm 2026-11-24 gập máy: 22:02 ngủ nhẹ, 22:32 thử ngủ đông thì lỗi
  `PM: hibernation: Error -12 creating image` (`Normal pages needed: 1988125 + 1024,
  available pages: 1850339`), máy quay lại ngủ nhẹ tới sáng.
- Lý do: trước khi ngủ đông kernel phải giải phóng RAM bằng cách đẩy ra swap, nhưng zram
  (`/dev/zram0`, ưu tiên 100) **nằm trong RAM**, nên đẩy vào đó không giải phóng được gì.
  Swapfile trên ổ (`/swap/swapfile`, ưu tiên -1) không được dùng tới.
- Sáng 2026-11-25 ngủ đông được vì lúc đó máy dùng ít RAM hơn, không phải vì đã sửa.
- Cách sửa khi bật lại ngủ đông: hook tắt zram trước khi ngủ đông, bật lại sau khi thức dậy
  (`systemctl stop dev-zram0.swap` / `start`). **Hook phải nằm trong
  `/usr/lib/systemd/system-sleep/`**: systemd 262 trên máy này không đọc
  `/etc/systemd/system-sleep/` (kiểm tra bằng
  `strings /usr/lib/systemd/systemd-sleep | grep system-sleep`). Lần đầu đặt sai chỗ nên hook
  không hề chạy. Thư mục trong `/usr/lib` thuộc gói, nên nếu đặt hook ở đó thì phải ghi nó vào
  `setup/install-system-files.sh` để cài lại được.

---

## Quy tắc: rút đầu thu chuột (hoặc tắt chuột) trước khi gập máy

Đầu thu USB của chuột Logitech G903 (`046d:c539`) được phép đánh thức máy. Chuột rất nhạy,
bàn rung hay xóc trong túi là máy thức dậy, khoảng 30 giây sau `logind` thấy nắp vẫn đóng
nên cho ngủ lại, rồi lặp lại. Hậu quả: hao pin gấp khoảng 3,5 lần và máy **ấm lên trong túi
chống sốc**.

| | Cắm đầu thu | Rút đầu thu |
|---|---|---|
| Tự thức dậy | 49 lần trong 3,7 giờ (2026-11-17) | 0 lần trong 12,4 giờ (đêm 2026-11-17) |
| Hao pin khi ngủ | ~1,4%/giờ (qua đêm 8 giờ ≈ 11%) | ~0,4%/giờ (qua đêm 8 giờ ≈ 3%) |

Đầu thu hoặc chuột không dây khác (ví dụ MX Master) có thể gây ra chuyện y hệt: thấy máy tự
thức thì rút thiết bị đó ra, rồi kiểm tra theo mục **Tìm thiết bị đánh thức máy**.

### Cách tắt hẳn (chưa áp dụng, chỉ dùng khi không muốn phải nhớ rút)

Tắt quyền đánh thức của riêng đầu thu. Chuột vẫn dùng bình thường, chỉ không đánh thức máy
bằng chuột được nữa (mở nắp hoặc bấm phím vẫn được):

```
echo 'ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c539", ATTR{power/wakeup}="disabled"' | sudo tee /etc/udev/rules.d/90-logitech-receiver-no-wakeup.rules
sudo udevadm control --reload
```

Áp dụng ngay không cần cắm lại: `echo disabled | sudo tee /sys/bus/usb/devices/<cổng>/power/wakeup`
(`<cổng>` là thư mục có `product` = `USB Receiver`, lúc kiểm tra là `3-1`).

---

## Gập nắp dùng màn hình ngoài: đánh thức bằng chuột hoặc bàn phím

Gập nắp khi cắm màn hình ngoài thì máy không ngủ ngay (logind coi là "docked", xem
bin/display-toggle). Để lâu không dùng thì máy vẫn **ngủ thật** (khoá sau 10 phút, tắt màn
hình sau 11 phút, rồi ngủ), như vậy là đúng ý: rời bàn thì máy ngủ. Lúc này nắp đang gập nên
phải đánh thức bằng thiết bị ngoài:

| Thiết bị | Đánh thức máy đang ngủ | Ghi chú |
|---|---|---|
| Chuột Logitech G903 (đầu thu USB) | **Được** (đã thử 2026-11-18) | Đầu thu phải đang cắm, chuột phải đang bật; click hoặc di chuột |
| Bàn phím USB có dây | **Được** (đã thử 2026-11-19 với GMMK Pro `320f:5044`, cắm thẳng vào laptop: bấm Space là dậy; Linux tự bật quyền đánh thức cho bàn phím USB) | Cắm thẳng vào cổng của laptop; qua hub, dock hay cổng USB của màn hình thì hub đó cũng phải cho phép đánh thức (xem bên dưới) |
| Bàn phím, touchpad Bluetooth (ProtoArc XK01) | **Không được** | Chip Bluetooth MediaTek (USB `0e8d:e025`, sau hub nội `3-5`) không hỗ trợ đánh thức từ xa: không có `power/wakeup` trong sysfs. Chỉ dùng được sau khi máy đã dậy |
| Nút nguồn laptop | **Được** | Bấm nhẹ, không giữ |

Từ 2026-11-19: khi gập nắp dùng màn hình ngoài, bin/display-toggle giữ một khoá
`handle-lid-switch` (xem bằng `systemd-inhibit --list`) để logind không tự cho máy ngủ vì nắp
đang gập. Trước đó logind đã cho máy ngủ bất ngờ (14:00) rồi lại ngủ tiếp 28 giây sau khi
bấm phím đánh thức, màn hình đen, phải vào TTY. Nghi do màn hình ngoài ở chế độ chờ sâu
thoáng mất tín hiệu nên logind tưởng không còn màn hình ngoài (DPMS off thì không: đã thử,
`Docked` vẫn `true`). Khoá tự hết khi mở nắp hoặc rút màn hình ngoài. Việc ngủ khi rời bàn
giờ do hypridle làm: 30 phút không dùng thì ngủ, cả khi đang cắm sạc, miễn là đang gập nắp
dùng màn hình ngoài.

Máy dậy thì màn hình ngoài sáng lại, hiện hyprlock; bàn phím Bluetooth kết nối lại sau vài
giây, gõ mật khẩu bình thường.

Thử nhanh: gập nắp, chạy `systemctl suspend` trên màn hình ngoài, đợi 10 giây rồi click chuột
(hoặc bấm một phím của bàn phím có dây).

Bàn phím có dây không đánh thức được (cắm qua hub): xem thiết bị và quyền đánh thức bằng lệnh ở
bước 4 của mục dưới (bỏ điều kiện `= enabled` để thấy cả thiết bị đang tắt), tìm hub mà bàn phím
cắm vào rồi bật thử `echo enabled | sudo tee /sys/bus/usb/devices/<hub>/power/wakeup`; được thì
giữ lâu dài bằng một udev rule theo `idVendor` / `idProduct` của hub, giống mẫu ở trên.

Như chuột: bỏ máy vào túi thì rút bàn phím có dây (và đầu thu chuột) ra, không thì bị đè cũng
làm máy tự thức dậy.

## Tìm thiết bị đánh thức máy

Các bước đã dùng ngày 2026-11-17, dùng lại được khi máy lại tự thức.

1. **Đếm số lần ngủ và thức.** Ngủ được vài giây đến vài phút rồi thức, lặp liên tục, là có
   thứ đánh thức máy:
   ```
   journalctl -b -k -o short-iso -g 'PM: suspend (entry|exit)'
   journalctl -b -u systemd-logind -g 'Lid'
   ```
   Thức dồn cục, không đều thường là tác động vật lý (chuột, bàn phím). Thức đều đặn theo chu
   kỳ thường là pin hoặc bộ điều khiển nguồn (EC).
2. **Bật log chi tiết khi ngủ** (tự tắt khi khởi động lại), gập máy 10–15 phút rồi mở ra:
   ```
   echo 1 | sudo tee /sys/power/pm_debug_messages
   journalctl -k --since '-30min' -g 'non-EC GPE|Notify sync|GPIO .* is active|Triggering wakeup'
   ```
   - `Wakeup after ACPI Notify sync` là do mở nắp, bình thường.
   - `ACPI non-EC GPE wakeup` kèm `GPIO N is active` là thiết bị nào đó đánh thức qua chân
     GPIO số N.
3. **Xem GPIO N đánh thức thiết bị nào.** `grep 'amd_gpio' /proc/interrupts` cho biết chân nào
   là `ACPI:Event` và đã kích hoạt bao nhiêu lần. Muốn biết nó gắn với thiết bị nào thì đọc
   bảng ACPI (cần gói `acpica`, gỡ đi sau khi xong):
   ```
   mkdir -p /tmp/acpi && sudo sh -c 'cp /sys/firmware/acpi/tables/DSDT /sys/firmware/acpi/tables/SSDT* /tmp/acpi/' && sudo chown -R $USER /tmp/acpi
   cd /tmp/acpi && for f in DSDT SSDT*; do iasl -d "$f"; done
   grep -n '_EVT' *.dsl
   ```
   Trong `_EVT`, mục `Case (0x..)` bằng số GPIO viết ở hệ 16 cho biết thiết bị được `Notify`.
   Trên máy này (`SSDT22`):

   | GPIO | Hex | Đánh thức | Ghi chú |
   |---|---|---|---|
   | 58 | `0x3A` | `XHC0` = USB `0000:c6:00.0` | cổng có đầu thu Logitech |
   | 59 | `0x3B` | `XHC1` = USB `0000:c4:00.4` | |
   | 61 | `0x3D` | `AZAL` | âm thanh HD |
   | 62 | `0x3E` | `ACP` | bộ xử lý âm thanh AMD |
   | 54 | `0x36` | `MP2C` | cảm biến AMD |
   | 0 | `0x00` | `PWRB` | nút nguồn |

   Tên ACPI (`XHC0`…) ứng với địa chỉ PCI nào thì xem `cat /proc/acpi/wakeup`.
4. **Tìm thiết bị USB đang được phép đánh thức** sau bộ điều khiển đó:
   ```
   for d in /sys/bus/usb/devices/*; do [ "$(cat $d/power/wakeup 2>/dev/null)" = enabled ] && echo "$(basename $d) $(cat $d/product 2>/dev/null) $(cat $d/idVendor):$(cat $d/idProduct) $(readlink -f $d)"; done
   ```
   Thiết bị nằm sau địa chỉ PCI ở bước 3 và có `wakeup=enabled` là thủ phạm. Rút nó ra rồi
   gập máy thử lại để xác nhận.
