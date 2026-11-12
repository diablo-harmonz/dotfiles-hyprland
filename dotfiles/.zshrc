# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"
# Manjaro's zsh setup: the system copy on Manjaro, the copy in ~/.config/zsh elsewhere (Arch)
ZDOTCFG="$HOME/.config/zsh"
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
  source /usr/share/zsh/manjaro-zsh-prompt
elif [[ -e "$ZDOTCFG/manjaro-zsh-config" ]]; then
  source "$ZDOTCFG/manjaro-zsh-config"
  source "$ZDOTCFG/manjaro-zsh-prompt"
fi

# nvm
# source /usr/share/nvm/init-nvm.sh
if [[ -e /usr/share/nvm/init-nvm.sh ]]; then
  unsetopt extendedglob
  source /usr/share/nvm/init-nvm.sh
  setopt extendedglob
fi
unsetopt correct

# Yazi file manager: `y` opens it, and the shell follows to the folder you leave in
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n $cwd && $cwd != "$PWD" ]] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

# zoxide: `z part-of-a-folder-name` jumps to a folder visited before (Yazi uses it too)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Neovim (LazyVim) for vim/vi
alias vim=nvim vi=nvim

# Fastfetch: show system info when opening a terminal window (not on a bare TTY)
if [[ -o interactive && $(tty) == *pts* ]] && command -v fastfetch >/dev/null; then
  fastfetch
fi
