# Neovim (LazyVim)

Copied from [LazyVim/starter](https://github.com/LazyVim/starter) (commit 803bc18,
Apache 2.0, see `LICENSE.lazyvim-starter`). Own changes: `:Tutor` is kept enabled.

The first `nvim` start downloads lazy.nvim and the plugins from GitHub. `lazy-lock.json`
pins their versions, so a reinstall gets the same set; `:Lazy update` updates them (and the
lock file, which is then committed).
