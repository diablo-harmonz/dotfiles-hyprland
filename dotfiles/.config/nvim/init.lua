-- File tree (nvim-tree) replaces the builts-in netrw: turn netrw off before anything loads
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
vim.opt.signcolumn = "yes"  -- Always keep room for marks like LSP errors (no jumping text)
-- %s draws that sign column first, left of the numbers
vim.opt.statuscolumn = "%s%3{v:virtnum ? '' : v:lnum} %#LineNr#%-2{v:virtnum || !v:relnum ? '' : v:relnum} "

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
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Leave Insert mode" })  -- Esc is far away

-- Move between split windows with Ctrl + h/j/k/l
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Vietnamese input (fcitx5 + Lotus) only while typing text: outside Insert mode it is
-- switched off, so commands like ci" dd ww reach Neovim untouched (Lotus swallowed the "
-- of ci"). Entering Insert mode turns it back on if it was on before. When Neovim loses
-- focus or quits, the earlier state is given back to the other windows (fcitx5 shares one
-- state between all windows). fcitx5-remote: 2 = Vietnamese on, 1 = off, -o on, -c off.
if vim.fn.executable("fcitx5-remote") == 1 then
  local im_was_on = false
  local function im_off()
    im_was_on = vim.trim(vim.fn.system({ "fcitx5-remote" })) == "2"
    if im_was_on then vim.system({ "fcitx5-remote", "-c" }) end
  end
  local function im_restore()
    if im_was_on then vim.system({ "fcitx5-remote", "-o" }) end
  end
  local function not_inserting() return not vim.fn.mode():match("^[iR]") end
  local group = vim.api.nvim_create_augroup("im-switch", {})
  vim.api.nvim_create_autocmd("InsertLeave", { group = group, callback = im_off })
  vim.api.nvim_create_autocmd("InsertEnter", { group = group, callback = im_restore })
  vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, { group = group,
    callback = function() if not_inserting() then im_off() end end })
  vim.api.nvim_create_autocmd({ "FocusLost", "VimLeavePre" }, { group = group,
    callback = function() if not_inserting() then im_restore() end end })
end

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
    "https://github.com/nvim-mini/mini.indentscope",  -- Line beside the current block
    "https://github.com/neovim/nvim-lspconfig",       -- Ready-made language server configs
    "https://github.com/nvim-tree/nvim-tree.lua",      -- File tree on the left
    "https://github.com/nvim-lualine/lualine.nvim",    -- Status line and buffer tabs
    "https://github.com/b0o/incline.nvim",             -- File name in each window's corner
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },  -- Parsers
    "https://github.com/folke/which-key.nvim",         -- Menu of keys after Space
    "https://github.com/lewis6991/gitsigns.nvim",      -- Git changes beside the line numbers
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

-- Current block (mini.indentscope): a line runs down the left of the block the cursor is
-- in. It also adds two text objects: ii = inside the block, ai = the block with its
-- first and last line (yii copies a function body, dai deletes a whole if).
local indentscope = require("mini.indentscope")
indentscope.setup({
    symbol = "│",
    draw = {
        delay = 50,                                       -- ms before the line appears
        animation = indentscope.gen_animation.none(),     -- draw it at once, no sliding
    },
    options = { try_as_border = true },  -- on a line like `fn run() {`, show the block below
})
-- No line in places that are not code: help pages, the fuzzy finder, terminals
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "help", "fzf", "netrw", "NvimTree" },
    callback = function() vim.b.miniindentscope_disable = true end,
})
vim.api.nvim_create_autocmd("TermOpen", {
    callback = function() vim.b.miniindentscope_disable = true end,
})

-- LSP (stage 4): a language server reads the code like a compiler does and tells Neovim
-- about errors, types, functions... nvim-lspconfig ships the settings for each server;
-- here only the command changes: on Arch, rustup keeps rust-analyzer out of PATH.
vim.lsp.config("rust_analyzer", {
    cmd = { "rustup", "run", "stable", "rust-analyzer" },
})
-- QML (Quickshell): Qt's qmlls is not in PATH on Arch. A folder is one project when it
-- holds .qmlls.ini (Quickshell fills that file with its import paths when it exists).
vim.lsp.config("qmlls", {
    cmd = { "/usr/lib/qt6/bin/qmlls" },
    root_markers = { ".qmlls.ini", ".git" },
})
-- Lua (this file, Hyprland's config) and shell scripts (bin/). bashls runs shellcheck for
-- its warnings. Packages: lua-language-server, bash-language-server, shellcheck, shfmt.
-- lua_ls: tell it about Neovim's own `vim` API so this file has no "undefined global vim".
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
        },
    },
})
vim.lsp.enable({ "rust_analyzer", "qmlls", "lua_ls", "bashls" })

-- Errors and warnings: a mark in the sign column and the message at the end of the line
vim.diagnostic.config({
    virtual_text = true,
    severity_sort = true,  -- errors before warnings when a line has both
})

-- Completion (stage 5): Neovim 0.12's own menu, opened while typing.
-- Sources in order: the language server (o), then words in open files (., w).
vim.opt.autocomplete = true
vim.opt.complete = "o,.,w"
vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }
-- Tab / Ctrl+n next item, Ctrl+p previous, Enter takes the selected item, Ctrl+e closes
vim.keymap.set("i", "<Tab>", function()
    return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true, desc = "Next completion item" })
vim.keymap.set("i", "<CR>", function()
    local selected = vim.fn.complete_info({ "selected" }).selected
    return (vim.fn.pumvisible() == 1 and selected ~= -1) and "<C-y>" or "<CR>"
end, { expr = true, desc = "Accept the selected completion" })

-- When a language server attaches to a file
vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP completion and keymaps",
    callback = function(ev)
        -- Let the server's items do their extras on accept (add a `use`, fill arguments)
        vim.lsp.completion.enable(true, ev.data.client_id, ev.buf)
        local map = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
        end
        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("<leader>cf", function() vim.lsp.buf.format({ async = false }) end, "Format the file")
        map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }),
                { bufnr = ev.buf })
        end, "Toggle type hints")
        -- Built in already: K docs · grn rename · gra code action · grr references ·
        -- [d / ]d previous / next error · Ctrl+o back after gd
    end,
})

-- File tree (stage 8): like the VS Code explorer. Space e opens/closes it,
-- Space o shows the current file in it. Inside: g? lists the keys.
require("nvim-tree").setup({
    view = { width = 30 },              -- columns wide
    renderer = { group_empty = true },  -- show a/b/c on one line when folders hold one folder
    git = { ignore = true },            -- hide what .gitignore ignores (target/, node_modules/)
})
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>o", "<cmd>NvimTreeFindFile<CR>", { desc = "Show this file in the tree" })

-- Status line and tabs (lualine): mode, git branch, file, errors at the bottom;
-- open files (buffers) as tabs at the top. Shift+h / Shift+l switch, Space x closes.
vim.opt.showmode = false  -- lualine shows the mode already (no second -- INSERT --)
vim.opt.winbar = " "      -- An empty bar at the top of each window: a gap below the tabs
require("lualine").setup({
    options = {
        theme = "auto",  -- follow the colour scheme (catppuccin-mocha)
        globalstatus = true,   -- one status line for the whole screen, not one per split
    },
    tabline = {
        lualine_a = {                -- left: every open file
            {
                "buffers",
                buffers_color = {
                    active = "lualine_a_normal",    -- Tab you are on: bright, like the mode box
                    inactive = "lualine_b_normal",  -- Other tabs: grey box instead of no background
                },
                symbols = { alternate_file = "" },  -- No # before the previously viewed file
                -- Readable names when the tree or the finder has the cursor (not NvimTree_1)
                filetype_names = { NvimTree = "Files", fzf = "Search" },
            },
        },
        lualine_z = { "tabs" },     -- right: Vim tab pages, when there is more than one
    },
})
vim.keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Close buffer" })

-- File name in the top-right corner of each window (incline); hidden when the cursor
-- is on that line, so it never covers code
require("incline").setup({ hide = { cursorline = true } })

-- Tree-sitter (stage 3): a real parser per language instead of regex colours, so code is
-- coloured by what it is (function, property, string), and folds / selections follow the
-- code's structure. nvim-treesitter (main branch) builds the parsers with tree-sitter-cli
-- and gcc; Neovim ships c, lua, markdown, query, vim, vimdoc already. :InspectTree shows
-- the tree of the open file; :TSUpdate rebuilds the parsers after a plugin update.
local ts_langs = {
    "bash", "css", "diff", "html", "javascript", "json", "python", "qmljs", "rust",
    "toml", "typescript", "yaml", "gitcommit", "git_rebase", "regex",
}
require("nvim-treesitter").install(ts_langs)  -- only fetches the missing ones
vim.api.nvim_create_autocmd("FileType", {
    desc = "Tree-sitter colours and indent when a parser exists",
    callback = function(ev)
        if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})

-- Format on save (stage 6): only where the formatter is the language's standard one
-- (rustfmt through rust-analyzer, qmlformat through qmlls). Other files: Space c f by hand.
vim.api.nvim_create_autocmd("BufWritePre", {
    desc = "Format Rust and QML before saving",
    pattern = { "*.rs", "*.qml" },
    callback = function(ev) vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 }) end,
})

-- Git (stage 7): gitsigns marks added / changed / deleted lines beside the numbers.
-- ]h / [h next / previous change, Space g p preview it, Space g r undo it (reset),
-- Space g b who wrote this line. Space g g opens lazygit full screen (q quits it).
local gitsigns = require("gitsigns")
gitsigns.setup({
    on_attach = function(buf)
        local map = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = buf, desc = desc })
        end
        map("]h", function() gitsigns.nav_hunk("next") end, "Next git change")
        map("[h", function() gitsigns.nav_hunk("prev") end, "Previous git change")
        map("<leader>gp", gitsigns.preview_hunk, "Preview this change")
        map("<leader>gr", gitsigns.reset_hunk, "Undo this change")
        map("<leader>gb", gitsigns.blame_line, "Who changed this line")
    end,
})
vim.keymap.set("n", "<leader>gg", function()
    vim.cmd("tabnew | terminal lazygit")
    vim.cmd("startinsert")
    -- Close the tab when lazygit quits
    vim.api.nvim_create_autocmd("TermClose", {
        buffer = 0, once = true,
        callback = function() vim.cmd("bdelete!") end,
    })
end, { desc = "Lazygit" })

-- Key menu (stage 9): press Space (or g, ], [ ...) and wait: a popup lists what can
-- follow, with the desc of each keymap. The groups below name the Space prefixes.
local wk = require("which-key")
wk.setup({ delay = 400 })   -- ms before the menu shows (fast typists never see it)
wk.add({
    { "<leader>c", group = "Code" },
    { "<leader>f", group = "Find" },
    { "<leader>g", group = "Git" },
    { "<leader>t", group = "Toggle" },
})
