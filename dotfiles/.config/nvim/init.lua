-- Own Neovim config, written by hand one stage at a time (roadmap: docs/neovim.md).
-- Empty on purpose: Neovim starts exactly as shipped. VS Code is the fallback meanwhile.
--
-- Display
vim.opt.number = true       -- Show line numbers.
vim.opt.relativenumber = true   -- Count lines up/down from the cursor
vim.opt.cursorline = true   -- Highlight the line the cursor is on
vim.opt.scrolloff = 8       -- Keep 8 lines visible above/below the cursor
vim.opt.wrap = true         -- Wrap long lines to fit the window (no sideways scrolling)
-- Line number column: real line number, then the distance from the cursor (for 5j, d3k...).
-- v:virtnum > 0 means the wrapped part of a line: leave it blank. The cursor line shows
-- no distance (it would be 0). %#LineNr# draws the distance in the dimmer colour.
vim.opt.statuscolumn = "%3{v:virtnum ? '' : v:lnum} %#LineNr#%-2{v:virtnum || !v:relnum ? '' : v:relnum} "

-- Indentation
vim.opt.expandtab = true    -- Tab key inserts spaces instead of a tab character.
vim.opt.tabstop = 4         -- A tab character already in a file is shown 4 columns wide
vim.opt.shiftwidth = 4      -- >> << and auto-indent move by 4 columns
vim.opt.smartindent = true  -- New line after { starts one level deeper

-- Search
vim.opt.ignorecase = true   -- /word also finds Word and WORD
vim.opt.smartcase = true    -- ...unless you type a capital: /Word finds only Word
vim.opt.inccommand = "split"    -- :s/old/new/ previews the result while typing

-- Leader key: the prefix for my own shortcuts (must come before the keymaps that use it)
vim.g.mapleader = " "

-- Keymaps: vim.keymap.set(mode, keys, action, { desc = "what it does" })
vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Close window" })
vim.keymap.set("n", "<leader>e", "<cmd>Explore<CR>", { desc = "File browser" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Move between split windows with Ctrl + h/j/k/l
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })
