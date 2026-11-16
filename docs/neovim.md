# Tự dựng cấu hình Neovim

Mục tiêu: hiểu từng phần của một trình soạn thảo kiểu IDE bằng cách tự dựng, thay vì dùng
cấu hình dựng sẵn. Làm từng giai đoạn, mỗi lần một thứ, dùng vài ngày cho quen rồi mới sang
giai đoạn sau.

## Cấu hình

- `nvim` (cũng là `vim`, `vi`) mở cấu hình tự dựng: `dotfiles/.config/nvim/init.lua`
  (link vào `~/.config/nvim`). LazyVim đã được gỡ (2026-11-15); file bắt đầu trống, Neovim
  chạy đúng như lúc mới cài, mọi dòng do bạn tự gõ theo từng giai đoạn.
- Plugin, lịch sử, cache của Neovim nằm ở `~/.local/share/nvim`, `~/.local/state/nvim`,
  `~/.cache/nvim` (không nằm trong repo).
- **VS Code là đường lui** trong lúc cấu hình còn dựng dở, và khi nó hỏng giữa tuần
  (debug có giao diện vẫn làm ở VS Code).

## Cách làm mỗi giai đoạn

1. Đọc mục giai đoạn bên dưới, mở cấu hình: `nvim ~/.config/nvim/init.lua`.
2. Thêm phần mới vào cuối file (hoặc nhờ Claude viết cùng, có chú thích từng dòng).
3. Lưu, rồi `:source %` hoặc thoát và mở lại `nvim`.
4. Lỗi khi mở: `:messages` để đọc; `:checkhealth` kiểm tra tổng thể.
5. Dùng vài ngày. Ổn thì commit: `git -C ~/Documents/personal/dotfiles-hyprland add -A dotfiles/.config/nvim && git -C ~/Documents/personal/dotfiles-hyprland commit -m "nvim: stage N ..."`.

Tra cứu trong Neovim: `:help <từ khoá>` (ví dụ `:help vim.pack`, `:help lsp`), tìm trong
help: `:help` rồi `/từ khoá`.

## Lộ trình

### Giai đoạn 0 · Thiết lập và phím tắt (xong 2026-11-16)

- Học: `vim.opt` (thiết lập), `vim.g.mapleader` (phím leader), `vim.keymap.set` (phím tắt),
  autocmd đơn giản.
- Thêm: số dòng tương đối, chuột, clipboard chung với hệ thống, thụt lề, tìm kiếm thông
  minh, lịch sử undo giữ sau khi đóng file; Space làm leader, Space w lưu, Space q đóng,
  Esc bỏ tô sáng, Ctrl + h/j/k/l giữa các cửa sổ, Space e trình duyệt file (netrw).
- Học kèm: `:Tutor` (khoảng 30 phút) cho các phím di chuyển và sửa cơ bản.
- Kiểm tra: `:set number?` in giá trị một thiết lập; `:map <leader>` liệt kê phím leader.

### Giai đoạn 1 · Màu sắc (plugin đầu tiên) (xong 2026-11-16: catppuccin mocha, nền trong suốt)

- Học: cài plugin bằng trình quản lý có sẵn của Neovim 0.12, `vim.pack.add({ ... })`;
  cập nhật bằng `:lua vim.pack.update()`.
- Thêm: một bảng màu (ví dụ catppuccin hoặc tokyonight), nền trong suốt để hợp với kitty.
- Kiểm tra: mở lại `nvim`, màu đổi; `:colorscheme` hiện tên bảng màu.

### Giai đoạn 2 · Tìm file và tìm chữ (xong 2026-11-16: fzf-lua)

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
  Neovim (Space g g).

### Giai đoạn 8 · Cây thư mục

- Thay netrw bằng oil.nvim (sửa thư mục như sửa file) hoặc neo-tree (cây bên trái).

### Giai đoạn 9 · Thanh trạng thái và menu phím

- Thêm: thanh trạng thái (mini.statusline hoặc lualine), which-key (bấm Space hiện menu
  các phím đã đặt).

### Bước cuối · Dùng Neovim thay VS Code

Khi đã làm được cả tuần trong Neovim mà không cần mở VS Code: chuyển dự án công việc sang
Neovim. VS Code vẫn giữ trên máy (xem docs/plan.md).
