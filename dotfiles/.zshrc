# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
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
