# Fastfetch logo, first found wins (kitty only; elsewhere the logo in the config stays):
#   ~/Pictures/fastfetch/<theme>.*       own picture for the active theme pack (bin/theme)
#   ~/.config/theme/fastfetch-logo.*     the theme pack's own logo
#   ~/Pictures/fastfetch/logo.*          own picture, only when the pack has no fastfetch.jsonc
# ~/Pictures/fastfetch links to fastfetch/ in the private wallpapers repo
# (setup/link-dotfiles.sh), so downloaded pictures never land in this public repo.
# A .gif plays animated (kitty icat); other formats are shown still.
fastfetch() {
  local args=() img=() theme
  theme=${$(readlink ~/.config/theme 2>/dev/null):t}
  [[ -n $theme ]] && img+=( ~/Pictures/fastfetch/$theme.*(N.) )
  if [[ -f ~/.config/theme/fastfetch.jsonc ]]; then
    args+=(--config ~/.config/theme/fastfetch.jsonc)
    img+=( ~/.config/theme/fastfetch-logo.*(N.) )
  else
    img+=( ~/Pictures/fastfetch/logo.*(N.) )
  fi
  if [[ -n $img && $TERM == xterm-kitty ]]; then
    if [[ ${img[1]:e:l} == gif ]]; then
      # one row lower and a column further left than still pictures: kitty draws the
      # animation a little up and right of its cell box
      args+=(--logo-type kitty-icat --logo "$img[1]" --logo-width 17 --logo-height 8 \
             --logo-padding-top 1 --logo-padding-left 1 --logo-padding-right 4)
    else
      args+=(--logo-type kitty --logo "$img[1]" --logo-width 18)
    fi
  fi
  command fastfetch "${args[@]}" "$@"
}

# Fastfetch: only in the welcome terminal opened at login (hypr/conf/startup-layout.lua);
# unset so shells started from it do not run it again. Type `fastfetch` any time.
# Runs before the instant prompt below: that redirects output away from the terminal
# while zsh loads, and fastfetch then falls back to the distro logo (no image in a pipe).
if [[ -n $WELCOME_FASTFETCH ]]; then
  unset WELCOME_FASTFETCH
  command -v fastfetch >/dev/null && fastfetch
fi

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

# Command colors in the prompt follow the wallpaper (Matugen writes this file; see
# dotfiles/.config/matugen/templates/zsh-highlight.zsh)
[[ ! -r ~/.config/zsh/highlight-colors.zsh ]] || source ~/.config/zsh/highlight-colors.zsh

# History (on top of Manjaro's: 10000 entries in ~/.zhistory, no duplicates, lines
# starting with a space are not saved): share it live between open terminals, and
# show a `!!`-style expansion before running it
setopt share_history hist_verify
unsetopt inc_append_history   # share_history already appends each command

# Tab completes as usual (Manjaro default); the grey autosuggestion is accepted with the
# Right arrow (or End), zsh-autosuggestions' default

# Aliases
alias reload-zsh='exec zsh'
alias edit-zsh='nvim ~/.zshrc'
alias back='cd ../'
alias home='cd ~'
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

# navi: command notebook (dotfiles/.config/navi/cheats). Ctrl+G opens it and puts the
# chosen command on the prompt; tldr <command> shows examples for common commands
command -v navi >/dev/null && eval "$(navi widget zsh)"

# zoxide: `z part-of-a-folder-name` jumps to a folder visited before (Yazi uses it too)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Neovim for vim/vi (own config built step by step: dotfiles/.config/nvim, docs/neovim.md)
alias vim=nvim vi=nvim
