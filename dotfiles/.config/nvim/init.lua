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
vim.opt.smartindent = true  -- New line after { starts one level depper

-- Search
vim.opt.ignorecase = true   -- /word also finds Word and WORD
vim.opt.smartcase = true    --...unless you type a capital: /Word finds only Word
vim.opt.inccommand = "split"    -- :s/old/new/ previews the result while typing
