# Tự dựng cấu hình Neovim

Mục tiêu: hiểu từng phần của một trình soạn thảo kiểu IDE bằng cách tự dựng, thay vì dùng
cấu hình dựng sẵn. Làm từng giai đoạn, mỗi lần một thứ, dùng vài ngày cho quen rồi mới sang
giai đoạn sau.

## Hai cấu hình song song

| Lệnh | Cấu hình | Dùng khi |
|---|---|---|
| `nvim` (cũng là `vim`, `vi`) | LazyVim, `dotfiles/.config/nvim` | Làm việc thật, khi cần chắc chạy |
| `nv` | Cấu hình tự dựng, `dotfiles/.config/nvim-own/init.lua` | Học, thử, dựng dần |

Hai cấu hình không ảnh hưởng nhau (Neovim tách chúng bằng `NVIM_APPNAME`: plugin, lịch sử,
dữ liệu nằm riêng ở `~/.local/share/nvim-own`). Khi `nv` đủ dùng hằng ngày, đổi `nvim` sang
nó (bước cuối) và xoá LazyVim nếu muốn.

**VS Code vẫn giữ** làm đường lui (debug có giao diện, lúc cấu hình Neovim hỏng giữa tuần).

## Cách làm mỗi giai đoạn

1. Đọc mục giai đoạn bên dưới, mở cấu hình: `nv ~/.config/nvim-own/init.lua`.
2. Thêm phần mới vào cuối file (hoặc nhờ Claude viết cùng, có chú thích từng dòng).
3. Lưu, rồi `:source %` hoặc thoát và mở lại `nv`.
4. Lỗi khi mở: `:messages` để đọc; `:checkhealth` kiểm tra tổng thể.
5. Dùng vài ngày. Ổn thì commit: `git -C ~/Documents/personal/dotfiles-hyprland add -A dotfiles/.config/nvim-own && git -C ~/Documents/personal/dotfiles-hyprland commit -m "nvim-own: stage N ..."`.

Tra cứu trong Neovim: `:help <từ khoá>` (ví dụ `:help vim.pack`, `:help lsp`), tìm trong
help: `:help` rồi `/từ khoá`.

## Lộ trình

### Giai đoạn 0 · Thiết lập và phím tắt (đã có)

File hiện tại: số dòng tương đối, chuột, clipboard chung với hệ thống, thụt lề 4 dấu cách,
tìm kiếm thông minh, lịch sử undo giữ sau khi đóng file, phím Space làm leader.

| Phím | Việc |
|---|---|
| Space w / Space q | Lưu / đóng cửa sổ |
| Esc | Bỏ tô sáng kết quả tìm |
| Ctrl + h/j/k/l | Chuyển giữa các cửa sổ chia đôi |
| J / K (khi chọn dòng) | Dời các dòng đang chọn xuống / lên |
| Space e | Trình duyệt file có sẵn (netrw) |

Học kèm: `:Tutor` (khoảng 30 phút) cho các phím di chuyển và sửa cơ bản.

### Giai đoạn 1 · Màu sắc (plugin đầu tiên)

- Học: cài plugin bằng trình quản lý có sẵn của Neovim 0.12, `vim.pack.add({ ... })`;
  cập nhật bằng `:lua vim.pack.update()`.
- Thêm: một bảng màu (ví dụ catppuccin hoặc tokyonight), nền trong suốt để hợp với kitty.
- Kiểm tra: mở lại `nv`, màu đổi; `:colorscheme` hiện tên bảng màu.

### Giai đoạn 2 · Tìm file và tìm chữ

- Học: fuzzy finder; fzf-lua (nhanh, dùng fzf đã có sẵn trên máy) hoặc telescope.
- Thêm: Space Space tìm file, Space / tìm chữ trong cả dự án (ripgrep đã cài), Space b
  danh sách buffer.

### Giai đoạn 3 · Tree-sitter (tô màu cú pháp chính xác)

- Học: Tree-sitter phân tích cú pháp; cài parser cho các ngôn ngữ dùng (lua, python,
  javascript, typescript, tsx, json, bash, markdown).
- Kiểm tra: `:InspectTree` xem cây cú pháp của file đang mở.

### Giai đoạn 4 · LSP (hiểu code: lỗi, gợi ý, nhảy tới định nghĩa)

- Học: Neovim 0.12 có sẵn client LSP; khai báo bằng `vim.lsp.config(...)` rồi
  `vim.lsp.enable({...})`. Server cài bằng pacman / npm (ví dụ `lua-language-server`,
  `typescript-language-server`, `pyright`) hoặc plugin mason.
- Phím có sẵn từ 0.11: `grn` đổi tên, `gra` code action, `grr` tìm chỗ dùng, `K` xem tài
  liệu, `Ctrl+]` nhảy tới định nghĩa, `[d` / `]d` lỗi trước / sau.
- Kiểm tra: `:checkhealth vim.lsp`.

### Giai đoạn 5 · Gợi ý khi gõ (completion)

- Học: completion có sẵn của LSP (`vim.lsp.completion`) hoặc plugin blink.cmp.
- Thêm: Tab / Enter chọn gợi ý, snippet.

### Giai đoạn 6 · Format và kiểm lỗi theo dự án

- Học: chạy Prettier, ESLint, Ruff… theo cấu hình của từng dự án (plugin conform.nvim).
- Thêm: format khi lưu.

### Giai đoạn 7 · Git

- Thêm: gitsigns (dòng thay đổi bên lề, xem / hoàn tác từng đoạn), mở lazygit trong
  Neovim (Space g g, như LazyVim).

### Giai đoạn 8 · Cây thư mục

- Thay netrw bằng oil.nvim (sửa thư mục như sửa file) hoặc neo-tree (cây bên trái).

### Giai đoạn 9 · Thanh trạng thái và menu phím

- Thêm: thanh trạng thái (mini.statusline hoặc lualine), which-key (bấm Space hiện menu
  các phím đã đặt, như LazyVim).

### Bước cuối · Cho `nv` thay LazyVim

Khi dùng `nv` cả tuần không cần mở `nvim`: đổi alias trong `.zshrc`
(`vim` / `vi` / `nvim` trỏ sang cấu hình mới), rồi quyết định giữ hay xoá
`dotfiles/.config/nvim` (LazyVim).
