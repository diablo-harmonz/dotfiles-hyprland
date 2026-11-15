-- Own Neovim config, built one stage at a time (roadmap: docs/neovim.md).
-- Start it with `nv` (zsh alias for NVIM_APPNAME=nvim-own nvim); plain `nvim` stays LazyVim.
-- Neovim 0.12: plugins come later through the built-in vim.pack, LSP through vim.lsp.config.
--
-- Stage 0 (this file): options and keymaps only, no plugins. Read a line, change it, save,
-- then :source % (or restart nv) to see what it does. `:help 'number'` explains any option.

------------------------------------------------------------------------------------------
-- Leader key: the prefix for your own shortcuts (Space, like LazyVim)
------------------------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

------------------------------------------------------------------------------------------
-- Options (:help options)
------------------------------------------------------------------------------------------
local o = vim.opt

-- Line numbers: absolute on the cursor line, relative elsewhere (5j / 3k at a glance)
o.number = true
o.relativenumber = true
o.cursorline = true            -- highlight the line the cursor is on
o.signcolumn = "yes"           -- keep the left column for later (git, diagnostics)

-- Mouse and clipboard: mouse works everywhere; y / p use the system clipboard (wl-clipboard)
o.mouse = "a"
o.clipboard = "unnamedplus"

-- Indent: 4 spaces, Tab inserts spaces, new lines keep the indent
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true

-- Search: case-insensitive unless the search has a capital letter; show matches as you type
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.inccommand = "split"         -- :%s/old/new preview in a split

-- Screen
o.termguicolors = true         -- full colours (kitty)
o.scrolloff = 8                -- keep 8 lines above / below the cursor
o.wrap = false                 -- long lines go off screen instead of wrapping
o.splitright = true            -- :vsplit opens on the right
o.splitbelow = true            -- :split opens below

-- Files: undo history survives closing the file; no swap files
o.undofile = true
o.swapfile = false
o.updatetime = 250             -- faster CursorHold (used by plugins later)

------------------------------------------------------------------------------------------
-- Keymaps (:help vim.keymap.set). Mode "n" = normal, "v" = visual, "i" = insert
------------------------------------------------------------------------------------------
local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Move between split windows with Ctrl + h/j/k/l
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Move selected lines up / down in visual mode (J / K), keeping the selection
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move lines down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move lines up" })

-- Built-in file browser (netrw) until a plugin replaces it in a later stage
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "File browser" })

------------------------------------------------------------------------------------------
-- Small comforts
------------------------------------------------------------------------------------------
-- Briefly highlight what was just yanked (copied)
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

-- Next stages (docs/neovim.md): 1 colour scheme · 2 fuzzy finder · 3 Tree-sitter ·
-- 4 LSP · 5 completion · 6 formatting · 7 git · 8 file tree · 9 status line
