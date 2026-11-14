# Powerlevel10k instant prompt: shows the last prompt at once while the rest loads.
# Stays close to the top; anything that asks for input must come before it.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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

# Powerlevel10k style picked with `p10k configure`, kept in this repo
# (dotfiles/.config/zsh/p10k-user.zsh); it replaces Manjaro's default p10k.zsh.
# The wizard writes to POWERLEVEL9K_CONFIG_FILE. Every p10k config unsets all
# POWERLEVEL9K_* first, so the path is set after sourcing. The wizard finds the
# `source` line below and the instant prompt line at the top, so it leaves this file
# (a symlink into the repo) alone.
[[ ! -r ~/.config/zsh/p10k-user.zsh ]] || source ~/.config/zsh/p10k-user.zsh
typeset -g POWERLEVEL9K_CONFIG_FILE=~/.config/zsh/p10k-user.zsh

# nvm
# source /usr/share/nvm/init-nvm.sh
if [[ -e /usr/share/nvm/init-nvm.sh ]]; then
  unsetopt extendedglob
  source /usr/share/nvm/init-nvm.sh
  setopt extendedglob
fi
unsetopt correct

# History (on top of Manjaro's: 10000 entries in ~/.zhistory, no duplicates, lines
# starting with a space are not saved): share it live between open terminals, and
# show a `!!`-style expansion before running it
setopt share_history hist_verify
unsetopt inc_append_history   # share_history already appends each command

# Tab: accept the grey autosuggestion when there is one, otherwise complete as usual
_tab_accept_or_complete() {
  if [[ -n $POSTDISPLAY ]]; then
    zle autosuggest-accept
  else
    zle expand-or-complete
  fi
}
zle -N _tab_accept_or_complete
bindkey '^I' _tab_accept_or_complete
# Shift+Tab: go backwards through the completion menu (Manjaro binds it to undo)
bindkey '^[[Z' reverse-menu-complete
zmodload zsh/complist && bindkey -M menuselect '^[[Z' reverse-menu-complete

# Aliases
alias reload-zsh='exec zsh'
alias edit-zsh='nvim ~/.zshrc'
alias documents='cd ~/Documents'
alias downloads='cd ~/Downloads'
# eza: ls with icons (Nerd Font), only when installed
command -v eza >/dev/null && alias ls='eza --icons=always'

# GitHub with two accounts. SSH host aliases github-work / github-personal are in
# ~/.ssh/config; the identity comes from ~/.gitconfig-work / ~/.gitconfig-personal
# (includeIf by folder: ~/Documents/work, ~/Documents/personal).
#   work-verify, personal-verify   check SSH login and the identity of this repo
#   work-remote, personal-remote   point origin at that account and use its email here
_gh_verify() {   # $1 = work | personal
  print "SSH auth:"
  ssh -T "git@github-$1" 2>&1
  print "\nGit identity:"
  print "  user.name  = $(git config user.name 2>/dev/null || print 'not in a repo')"
  print "  user.email = $(git config user.email 2>/dev/null || print 'not in a repo')"
  print "\nRemote:"
  git remote -v 2>/dev/null || print "  not in a repo"
  print "\nRepo path:"
  git rev-parse --show-toplevel 2>/dev/null || print "  not in a repo"
}

_gh_remote() {   # $1 = work | personal
  local current repo_path new_url email
  current=$(git remote get-url origin 2>/dev/null)
  if [[ -z $current ]]; then
    print "No remote named origin"
    return 1
  fi
  email=$(git config -f ~/.gitconfig-$1 user.email)
  if [[ -z $email ]]; then
    print "No user.email in ~/.gitconfig-$1"
    return 1
  fi
  # user/repo from git@github.com:user/repo.git, git@github-xxx:user/repo.git or https
  repo_path=$(print -r -- "$current" | sed -E 's#^(git@[^:]+:|https://[^/]+/)##')
  new_url="git@github-$1:$repo_path"
  git remote set-url origin "$new_url" && git config user.email "$email"
  print "Remote: $new_url"
  print "Email : $(git config user.email)"
}

work-verify()     { _gh_verify work }
personal-verify() { _gh_verify personal }
work-remote()     { _gh_remote work }
personal-remote() { _gh_remote personal }

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

# Fastfetch: only in the welcome terminal opened at login (hypr/conf/startup-layout.lua);
# unset so shells started from it do not run it again. Type `fastfetch` any time.
if [[ -n $WELCOME_FASTFETCH ]]; then
  unset WELCOME_FASTFETCH
  command -v fastfetch >/dev/null && fastfetch
fi
