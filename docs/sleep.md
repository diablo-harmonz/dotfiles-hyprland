# Gập máy và chế độ ngủ

Ghi chú cho ThinkPad T14 Gen 6 (AMD). Gập máy là máy **ngủ (suspend)**, không cần tắt. Máy
chỉ có chế độ ngủ nhẹ `s2idle` (`cat /sys/power/mem_sleep`), chưa có ngủ đông (hibernate)
vì swap là zram.

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
| Bàn phím USB có dây | **Được** theo lý thuyết, chưa thử (Linux tự bật quyền đánh thức cho bàn phím USB) | Cắm thẳng vào cổng của laptop; qua hub, dock hay cổng USB của màn hình thì hub đó cũng phải cho phép đánh thức (xem bên dưới) |
| Bàn phím, touchpad Bluetooth (ProtoArc XK01) | **Không được** | Chip Bluetooth MediaTek (USB `0e8d:e025`, sau hub nội `3-5`) không hỗ trợ đánh thức từ xa: không có `power/wakeup` trong sysfs. Chỉ dùng được sau khi máy đã dậy |
| Nút nguồn laptop | **Được** | Bấm nhẹ, không giữ |

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
