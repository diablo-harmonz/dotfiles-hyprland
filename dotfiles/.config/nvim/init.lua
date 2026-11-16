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

-- Editing
vim.opt.clipboard = "unnamedplus"  -- y / p use the system clipboard (paste into Firefox etc.)
vim.opt.undofile = true            -- Keep undo history after closing the file
vim.opt.splitright = true          -- :vsplit opens the new window on the right
vim.opt.splitbelow = true          -- :split opens the new window below

-- Autocmd: when something happens, run a function
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Flash the text that was just copied",
    callback = function()
        vim.hl.on_yank({ timeout = 200 })
    end,
})

-- Plugins: Neovim 0.12's built-in manager downloads them from GitHub
-- and pins their versions in nvim-pack-lock.json (next to this file)
vim.pack.add({
    { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
    "https://github.com/ibhagwan/fzf-lua",            -- Fuzzy finder
    "https://github.com/nvim-tree/nvim-web-devicons", -- File icons for it
})

-- Colour scheme
require("catppuccin").setup({
    flavour = "mocha",              -- Dark variant (latte is the light one)
    transparent_background = true,  -- Let kitty's see-through background show
})
vim.cmd.colorscheme("catppuccin")

-- Rust: :RustFmt (bundled with Neovim) still passes rustfmt's removed --write-mode flag
-- unless told the installed rustfmt is new enough for --emit=files
vim.g.rustfmt_emit_files = 1

-- Fuzzy finder (fzf-lua): type a few letters, Enter opens the match
local fzf = require("fzf-lua")
fzf.setup({
    grep = {
        -- ripgrep skips hidden files and folders by default, and this repo keeps its
        -- configs under dotfiles/.config: search those too, but never inside .git
        rg_opts = "--hidden --glob=!.git --column --line-number --no-heading"
            .. " --color=always --smart-case --max-columns=4096 -e",
    },
})
vim.keymap.set("n", "<leader><leader>", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>/", fzf.live_grep, { desc = "Search text in project" })
vim.keymap.set("n", "<leader>b", fzf.buffers, { desc = "Open buffers" })
vim.keymap.set("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fh", fzf.helptags, { desc = "Search help" })
