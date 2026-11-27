# Gập máy và chế độ ngủ

Ghi chú cho ThinkPad T14 Gen 6 (AMD). Gập máy là máy **ngủ nhẹ** (`s2idle`, xem
`cat /sys/power/mem_sleep`), mở ra dùng ngay. Gập quá **30 phút** (chạy pin hay cắm sạc đều
vậy) thì máy tự **ngủ đông**: lưu RAM xuống `/swap/swapfile` rồi tắt hẳn. Bật lại bằng nút
nguồn, nhập mật khẩu LUKS ở GRUB, máy về màn khoá với các cửa sổ cũ. Có từ 2026-11-24:
`setup/enable-hibernate.sh` (swapfile 20 GB, `resume=`), `setup/system/logind.conf.d/lid.conf`,
`sleep.conf.d/hibernate.conf` và phần tắt zram quanh lúc ngủ đông `setup/system/zram-hibernate/`
(cài bằng `setup/install-system-files.sh`). Gập máy khi đang cắm màn hình ngoài thì không ngủ
(xem `bin/display-toggle`). Menu nguồn có nút Hibernate để ngủ đông ngay.

---

## Ngủ đông: lỗi zram và lỗi GPU (2026-11-24 đến 2026-11-25)

### Chuyện gì đã xảy ra

Cùng một lần khởi động (từ 12:34 ngày 24/11), máy ngủ đông 4 lần:

| Lúc | Cách gọi | Kết quả |
|---|---|---|
| 24/11 12:37 | `systemctl hibernate` | thành công |
| 24/11 16:45 → 17:15 | gập máy, 30 phút sau tự ngủ đông | thành công |
| 24/11 22:32 | gập máy, 30 phút sau tự ngủ đông | **bỏ dở**: `Error -12 creating image`, quay lại ngủ nhẹ tới sáng |
| 25/11 06:16 | `systemctl hibernate` | nạp lại RAM được nhưng **GPU không khôi phục**, Hyprland hỏng, phải khởi động lại |

Lỗi GPU lúc 06:16 (`amdgpu`, PCI `c4:00.0`, device `0x1114`, khối `gfx_v11_0`):
```
amdgpu: MES failed to respond to msg=SET_HW_RSRC_1
[drm:mes_v11_0_hw_init [amdgpu]] *ERROR* failed mes_v11_0_set_hw_resources_1, r=-110
amdgpu: resume of IP block <gfx_v11_0> failed -110
amdgpu: PM: dpm_run_callback(): pci_pm_restore returns -110
```
rồi `ring sdma0 timeout`, `MODE2 reset`, `Ring comp_1.2.0 reset failed`. Lúc đó: kernel
`linux 7.3.5.arch1-1`, `linux-firmware 20261019-1`, `mesa 26.3.1`, `hyprland 0.57.2`.

### Nguyên nhân (giả thuyết, khớp với mọi lần thử)

1. **zram làm ngủ đông bỏ dở khi RAM bận.** Trước khi ngủ đông kernel phải giải phóng RAM
   bằng cách đẩy ra swap. zram (`/dev/zram0`, ưu tiên 100) **nằm trong RAM**, nên đẩy vào đó
   không giải phóng được gì; swapfile trên ổ (ưu tiên -1) không được dùng tới. Lúc 22:32:
   `Normal pages needed: 1988125 + 1024, available pages: 1850339`.
2. **Lần bỏ dở làm hỏng lần sau.** Khi bỏ dở, GPU bị đóng băng rồi đánh thức giữa chừng
   (đường xử lý hiếm gặp). Lần ngủ đông kế tiếp trong cùng lần khởi động thì GPU (firmware MES)
   không khôi phục được. Hai lần thành công trước đó đều không đi qua lần bỏ dở nào.

Chỉ có một lần lỗi GPU nên chưa chứng minh chắc chắn được ý 2. Nếu lỗi GPU xuất hiện lại mà
**không** có lần bỏ dở nào trước đó trong cùng lần khởi động, thì GPU có lỗi riêng: khi đó đổi
`lid.conf` về `HandleLidSwitch=suspend`, bước 30 phút trong `hypridle.conf` về
`systemctl suspend`, và chờ `linux`/`linux-firmware` mới (đọc changelog tìm `MES`,
`gfx_v11`, `S4`, `pci_pm_restore`).

### Cách sửa: tắt zram trước khi ngủ đông, bật lại sau

`setup/system/zram-hibernate/zram-hibernate` (cài vào `/usr/local/lib/zram-hibernate`) chạy từ
drop-in `zram.conf` (cài vào `/etc/systemd/system/<unit>.service.d/zram.conf` cho
`systemd-hibernate`, `systemd-hybrid-sleep`; **không** gắn cho `systemd-suspend-then-hibernate`, xem
mục dưới):
- `ExecStartPre` → `pre`: `swapoff /dev/zram0`. Dữ liệu trong zram về RAM hoặc xuống swapfile,
  kernel giải phóng được RAM thật.
- `ExecStartPost` → `post`, chạy khi **cả lần ngủ đã xong**:
  `systemctl --no-block start dev-zram0.swap`. Không dùng `swapon`: khi zram tắt, systemd dừng
  luôn `systemd-zram-setup@zram0` và **xoá thiết bị** (kích thước 0), nên phải để systemd tạo lại.
- Log: `journalctl -b -t zram-hibernate`. Thử mà không ngủ:
  `sudo /usr/local/lib/zram-hibernate pre`, xem `swapon --show`, rồi `... post`.

### Gập máy (suspend-then-hibernate): để zram bật (2026-11-26)

Bản đầu là hook trong `/usr/lib/systemd/system-sleep/` (systemd 262 ở đây không đọc
`/etc/systemd/system-sleep/`). Với `suspend-then-hibernate`, systemd chạy `pre` lúc bắt đầu ngủ
nhẹ và `post` **sau phần ngủ nhẹ, ngay trước khi ngủ đông**. Mọi lần tắt zram ở kiểu ngủ này
đều hỏng: bật máy phải nhập LUKS **hai lần** (lần đầu kernel đọc ảnh nhưng khôi phục thất bại,
máy tự khởi động lại), rồi `PM: Image not found (code -22)`, mất phiên.

| Lần | zram | Kết quả |
|---|---|---|
| 24/11 17:15, gập máy | bật (chưa có hook) | ✅ |
| 25/11 18:14, gập máy | hook: tắt khi ngủ nhẹ, `post` bật lại ngay trước ngủ đông | ❌ |
| 26/11 04:50, sleep bằng lệnh | hook: tắt, `post` hẹn bật sau (`systemd-run` xếp sau unit ngủ) | ❌ |
| 26/11 05:57, thử 2 phút | bật (hook thay bằng script rỗng qua bind mount trong `/run`) | ✅ |
| 26/11 06:06, thử 2 phút | drop-in: tắt trước khi ngủ nhẹ, không làm gì giữa chừng | ❌ |

Cách thử: `HibernateDelaySec=2min` trong `/run/systemd/sleep.conf.d/zz-s2h-test.conf` (mất khi
khởi động lại, nên hỏng cũng tự về như cũ), rồi `systemctl suspend-then-hibernate`.
Kết luận theo các lần trên: ở kiểu ngủ này **không tắt zram**. Vì sao tắt zram (thiết bị bị
`systemd-zram-setup` reset về 0) rồi ngủ nhẹ làm hỏng lần khôi phục sau đó thì chưa rõ. Cái giá:
nếu zram đang chứa nhiều, lần ngủ đông có thể bỏ dở với `Error -12`; khi đó systemd quay lại
ngủ nhẹ (như 24/11 22:32), không mất gì, chỉ tốn pin. Ngủ đông bằng tay vẫn tắt zram trước
(25/11 12:10, 12:16 đều ổn).

### Vân tay kẹt sau khi ngủ đông (2026-11-27)

Gập máy là hyprlock bắt đầu đọc vân tay, nên cảm biến Synaptics vào giấc ngủ khi đang "bận"
(fprintd: `Unexpected error while suspending device: The device is still busy`). Sau lần ngủ
đông 26/11 17:01 → 27/11 11:01, hyprlock không thoát dù đã mở khoá bằng mật khẩu, và mọi lần
đọc vân tay sau đó hỏng: `Device was already claimed` (KeePassXC Quick Unlock treo trong hộp
thoại polkit). Tắt hyprlock chưa đủ (`Error closing device after disconnect`, fprintd thấy 3
thiết bị); `sudo systemctl restart fprintd` mới chữa được.
Cách sửa: drop-in `setup/system/fprintd-resume/fprintd.conf` cho `systemd-hibernate`,
`systemd-hybrid-sleep`, `systemd-suspend-then-hibernate`: `ExecStartPost` khởi động lại fprintd
khi cả lần ngủ đã xong (fprintd khởi động theo D-Bus, lần dùng sau nhận lại cảm biến).
Sửa lần 2 (27/11 22:08): bản đầu dùng `--no-block`, lệnh restart chạy cùng lúc hyprlock nhận
lại cảm biến (logind báo "đã dậy" ngay khi unit xong), nên hyprlock mất cảm biến: `Device was
not claimed before use`, màn khoá không nhận vân tay. Giờ restart chạy xong rồi unit mới kết
thúc (`timeout 15 systemctl restart`), hyprlock nhận cảm biến từ fprintd mới.

### Ảnh ngủ đông quá lớn khi zram bật (2026-11-27)

27/11 16:29 gập máy, 16:59 ngủ đông bỏ dở: `Normal pages needed: 1993511 + 1024, available
pages: 1844928`, `Error -12 creating image`, máy ngủ nhẹ tiếp tới 22:08. Kiểu ngủ này giữ zram
bật (xem trên), dữ liệu zram nằm trong RAM. Cách sửa: `/sys/power/image_size` từ mặc định
~6 GiB (2/5 RAM) xuống 3 GiB qua `setup/system/zram-hibernate/hibernate-image-size.conf`
(tmpfiles.d). Kernel phải ép ảnh dưới mức đó nên đẩy nhiều hơn ra `/swap/swapfile` trước khi
tạo ảnh. Cái giá: vài giây đầu sau khi dậy chương trình đọc lại từ swapfile.

### Thử lại sau khi sửa (2026-11-25, khởi động lại sạch trước khi thử)

| Lần | Tình trạng máy | Hook | Ảnh RAM | GPU |
|---|---|---|---|---|
| 12:10 | RAM 2,2 GB, zram trống | zram off (0 KiB) → bật lại | 3,5 GB, tạo trong 0,5 s | không lỗi |
| 12:16 | RAM đầy (còn 224 MB trống), zram 2,9 GB | zram off (3,4 GB dồn ra) → bật lại | 6,2 GB; cần 1634628 trang, còn 2203698 | không lỗi |

Lần 12:16 khắc nghiệt hơn lần gây `Error -12` mà vẫn thành công. Sau đó bật lại tự ngủ đông
khi gập máy và khi để không 30 phút lúc chạy pin.

Nếu vẫn thấy lỗi: `journalctl -b -k | grep -E 'hibernation|Error -12|MES failed|pci_pm_restore'`
và `journalctl -b -t zram-hibernate`.

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
