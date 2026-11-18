#!/usr/bin/env bash
# setup-git.sh: guided Git + GitHub setup, step by step.
#   setup/setup-git.sh            asks first: one GitHub account or two (personal + work)
#   setup/setup-git.sh one        one account, no question
#   setup/setup-git.sh two        personal + work, no question
#   setup/setup-git.sh personal   only the personal profile of the two-account setup
#   setup/setup-git.sh work       only the work profile of the two-account setup
#   setup/setup-git.sh check      show what is set up, change nothing
# Every step shows what is already there and asks before changing anything, so running it
# again is safe. Nothing personal is stored in this script: names, emails and GitHub
# accounts are typed in while it runs. Guide (Vietnamese): docs/plan.md, "1. Git".
#
# One account (plain Git, nothing special to remember):
#   ~/.gitconfig          user.name / user.email for every repo, wherever it is cloned
#   ~/.ssh/id_ed25519     the SSH key; ssh uses it for github.com by itself
#   clone anywhere:       git clone git@github.com:OWNER/REPO.git
# Two accounts (one identity per folder), for each profile P = personal, work:
#   ~/Documents/P/        repos of that account live here
#   ~/.gitconfig-P        user.name / user.email of that account
#   ~/.gitconfig          includeIf "gitdir:~/Documents/P/" -> ~/.gitconfig-P
#   ~/.ssh/id_ed25519_P   the SSH key of that account
#   ~/.ssh/config         Host github-P -> github.com with that key only
#   clone into the folder: git clone git@github-P:OWNER/REPO.git ~/Documents/P/REPO
#
#   1 Packages        git, openssh
#   2 Defaults        init.defaultBranch main, core.editor nano
#   3 Identity        (and the folder for two accounts)
#   4 SSH key         (and the github-P alias for two accounts)
#   5 GitHub          paste the public key on GitHub, then test the connection
set -uo pipefail

# --- look ----------------------------------------------------------------------------
if [ -t 1 ]; then
    B=$'\e[1m' D=$'\e[2m' R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[36m' N=$'\e[0m'
else
    B="" D="" R="" G="" Y="" C="" N=""
fi
step()  { printf '\n%s━━ Step %s · %s%s\n' "$B$C" "$1" "$2" "$N"; }
info()  { printf '   %s\n' "$*"; }
good()  { printf '   %s✔%s %s\n' "$G" "$N" "$*"; }
warn()  { printf '   %s!%s %s\n' "$Y" "$N" "$*"; }
bad()   { printf '   %s✘%s %s\n' "$R" "$N" "$*"; }
ask()   {   # $1 = question; default No
    local a
    read -r -p "   $1 [y/N] " a
    [[ "$a" =~ ^[Yy]$ ]]
}
prompt() {   # $1 = question, $2 = default; prints the answer
    local a
    read -r -p "   $1${2:+ [$2]}: " a
    printf '%s' "${a:-$2}"
}

# GitHub's published ed25519 host key fingerprint (docs.github.com, "GitHub's SSH key
# fingerprints"): compare it with what ssh shows the first time it connects
GITHUB_FP="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"
SSH_CONFIG="$HOME/.ssh/config"

CHECK=0
case "${1:-ask}" in
    ask)
        printf '%sGit setup%s: how many GitHub accounts on this machine?\n' "$B" "$N"
        printf '   1) One account: plain Git, clone anywhere with git@github.com:...\n'
        printf '   2) Two accounts: personal + work, one identity per folder\n'
        printf '      (~/Documents/personal, ~/Documents/work; clone with git@github-personal:...)\n'
        read -r -p "   Choose 1 or 2 [1]: " choice
        case "${choice:-1}" in
            1) PROFILES=(default) ;;
            2) PROFILES=(personal work) ;;
            *) echo "   Nothing chosen, stopped." >&2; exit 2 ;;
        esac
        ;;
    one) PROFILES=(default) ;;
    two) PROFILES=(personal work) ;;
    personal|work) PROFILES=("$1") ;;
    check)
        CHECK=1
        # Report whatever is set up: the one-account parts, and each two-account profile
        # that has something on this machine
        PROFILES=()
        if git config --global --get user.email >/dev/null 2>&1 || [ -e "$HOME/.ssh/id_ed25519" ]; then
            PROFILES+=(default)
        fi
        for p in personal work; do
            if [ -e "$HOME/.gitconfig-$p" ] || [ -e "$HOME/.ssh/id_ed25519_$p" ]; then
                PROFILES+=("$p")
            fi
        done
        [ ${#PROFILES[@]} -gt 0 ] || PROFILES=(default)   # nothing yet: show the one-account parts
        ;;
    *) echo "usage: setup-git.sh [one|two|personal|work|check]   (no argument: asks)" >&2; exit 2 ;;
esac

label() { [ "$1" = default ] && echo "one account" || echo "$1"; }
names=(); for p in "${PROFILES[@]}"; do names+=("$(label "$p")"); done
printf '%sGit setup%s %s(%s%s)%s\n' "$B" "$N" "$D" "$(IFS=,; echo "${names[*]}" | sed 's/,/, /g')" \
    "$([ "$CHECK" = 1 ] && echo '; check only')" "$N"

# --- 1 packages ----------------------------------------------------------------------
step 1 "Packages"
missing=()
for p in git openssh; do pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p"); done
if [ ${#missing[@]} -eq 0 ]; then
    good "git and openssh are installed ($(git --version | awk '{print $3}'))."
elif [ "$CHECK" = 1 ]; then
    warn "Missing: ${missing[*]}"
elif ask "Install ${missing[*]} now (sudo pacman -S --needed)?"; then
    sudo pacman -S --needed "${missing[@]}" || { bad "Install failed."; exit 1; }
else
    bad "Git is needed for the next steps."; exit 1
fi

# --- 2 defaults ----------------------------------------------------------------------
step 2 "Defaults"
set_default() {   # $1 = key, $2 = wanted value
    local now
    now=$(git config --global --get "$1" 2>/dev/null || true)
    if [ "$now" = "$2" ]; then
        good "$1 = $2"
    elif [ "$CHECK" = 1 ]; then
        warn "$1 = ${now:-(not set)}, suggested: $2"
    elif ask "Set $1 = $2 (now: ${now:-not set})?"; then
        git config --global "$1" "$2" && good "$1 = $2"
    fi
}
set_default init.defaultBranch main
set_default core.editor nano

# --- 3-5 per profile -----------------------------------------------------------------
for P in "${PROFILES[@]}"; do
    if [ "$P" = default ]; then
        NAME="one account"
        CFG=(--global)                      # identity for every repo
        CFG_SHOWN="~/.gitconfig"
        KEY="$HOME/.ssh/id_ed25519"         # the key ssh tries by itself
        HOST="github.com"
    else
        NAME="$P"
        CFG=(-f "$HOME/.gitconfig-$P")
        CFG_SHOWN="~/.gitconfig-$P"
        KEY="$HOME/.ssh/id_ed25519_$P"
        HOST="github-$P"
    fi
    KEY_SHOWN="~/.ssh/$(basename "$KEY")"

    step 3 "Identity · $NAME"
    if [ "$P" != default ]; then
        if [ -d "$HOME/Documents/$P" ]; then good "Folder ~/Documents/$P"
        elif [ "$CHECK" = 1 ]; then warn "Folder ~/Documents/$P is missing"
        elif ask "Create ~/Documents/$P?"; then mkdir -p "$HOME/Documents/$P" && good "Created ~/Documents/$P"
        fi
    fi

    name=$(git config "${CFG[@]}" --get user.name 2>/dev/null || true)
    email=$(git config "${CFG[@]}" --get user.email 2>/dev/null || true)
    if [ -n "$name" ] && [ -n "$email" ]; then
        good "Identity in $CFG_SHOWN: $name <$email>"
    elif [ "$CHECK" = 1 ]; then
        warn "No identity in $CFG_SHOWN"
    fi
    if [ "$CHECK" = 0 ] && { [ -z "$name" ] || [ -z "$email" ] || ask "Change this identity?"; }; then
        info "The name and email shown on your commits (your GitHub email, or the noreply"
        info "address from github.com/settings/emails to keep the real one private)."
        name=$(prompt "Name" "$name")
        email=$(prompt "Email" "$email")
        if [ -n "$name" ] && [ -n "$email" ]; then
            git config "${CFG[@]}" user.name "$name"
            git config "${CFG[@]}" user.email "$email"
            good "Saved to $CFG_SHOWN"
        else
            warn "Name or email empty: identity not saved."
        fi
    fi

    if [ "$P" != default ]; then
        # The trailing / matters: it matches every repo below that folder
        inc=$(git config --global --get "includeIf.gitdir:~/Documents/$P/.path" 2>/dev/null || true)
        if [ "$inc" = "~/.gitconfig-$P" ]; then
            good "Repos in ~/Documents/$P/ use ~/.gitconfig-$P (includeIf)"
        elif [ "$CHECK" = 1 ]; then
            warn "includeIf for ~/Documents/$P/ is missing"
        elif ask "Make repos in ~/Documents/$P/ use ~/.gitconfig-$P (includeIf in ~/.gitconfig)?"; then
            git config --global "includeIf.gitdir:~/Documents/$P/.path" "~/.gitconfig-$P" \
                && good "includeIf added"
        fi
    fi

    step 4 "SSH key · $NAME"
    if [ -f "$KEY" ]; then
        good "Key $KEY_SHOWN ($(ssh-keygen -lf "$KEY.pub" 2>/dev/null | awk '{print $2}'))"
    elif [ "$CHECK" = 1 ]; then
        warn "No key $KEY_SHOWN"
    elif ask "Create the SSH key $KEY_SHOWN?"; then
        info "ssh-keygen asks for a passphrase: choose one (you type it on every push;"
        info "no ssh-agent on this machine). Enter it twice."
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "${email:-$P}" -f "$KEY" && good "Key created"
    fi

    if [ "$P" != default ]; then
        if [ -f "$SSH_CONFIG" ] && grep -qE "^Host[[:space:]]+$HOST([[:space:]]|$)" "$SSH_CONFIG"; then
            good "Alias $HOST in ~/.ssh/config"
        elif [ "$CHECK" = 1 ]; then
            warn "Alias $HOST is missing from ~/.ssh/config"
        elif ask "Add the alias $HOST to ~/.ssh/config (github.com with this key only)?"; then
            mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
            # A blank line before the block, also when the file ends without a newline
            { [ -s "$SSH_CONFIG" ] && printf '\n'
              printf 'Host %s\n    HostName github.com\n    User git\n    IdentityFile ~/.ssh/id_ed25519_%s\n    IdentitiesOnly yes\n' "$HOST" "$P"
            } >> "$SSH_CONFIG"
            chmod 600 "$SSH_CONFIG"
            good "Alias added"
        fi
    fi

    step 5 "GitHub · $NAME"
    if [ "$CHECK" = 1 ]; then
        info "Test by hand: ssh -T git@$HOST"
        continue
    fi
    if [ ! -f "$KEY.pub" ]; then
        warn "No public key yet: skipped."
        continue
    fi
    if ask "Show the public key to add it on GitHub?"; then
        info "Sign in to GitHub ($NAME), open github.com/settings/ssh/new,"
        info "Title: this machine's name, Key type: Authentication Key, Key: the line below."
        printf '\n%s\n\n' "$(cat "$KEY.pub")"
        if command -v wl-copy >/dev/null && ask "Copy it to the clipboard?"; then
            wl-copy < "$KEY.pub" && good "Copied (Ctrl+V on the GitHub page)"
        fi
        read -r -p "   Press Enter when the key is saved on GitHub. " _
    fi
    if ask "Test the connection now (ssh -T git@$HOST)?"; then
        info "First time only, ssh asks to trust github.com: the fingerprint it shows must be"
        info "  $GITHUB_FP"
        info "then type yes. Then your key passphrase."
        out=$(ssh -T "git@$HOST" 2>&1)
        printf '%s\n' "$out" | sed 's/^/     /'
        if grep -q "successfully authenticated" <<<"$out"; then
            good "GitHub knows this key."
        else
            bad "Not connected: check the key on GitHub, then run this step again."
        fi
    fi
done

printf '\n%s━━ Done%s\n' "$B$C" "$N"
for P in "${PROFILES[@]}"; do
    if [ "$P" = default ]; then
        info "Clone anywhere:  git clone git@github.com:OWNER/REPO.git"
    else
        info "$P: clone with  git clone git@github-$P:OWNER/REPO.git ~/Documents/$P/REPO"
    fi
done
info "Check later: setup/setup-git.sh check"
