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

# Fastfetch: show system info when opening a terminal window (not on a bare TTY)
if [[ -o interactive && $(tty) == *pts* ]] && command -v fastfetch >/dev/null; then
  fastfetch
fi
