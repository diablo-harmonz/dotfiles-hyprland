#!/usr/bin/env bash
# setup-git.sh: guided Git + GitHub setup with one identity per folder, step by step.
#   setup/setup-git.sh            asks first: one account (personal) or two (personal + work)
#   setup/setup-git.sh personal   only the personal profile (steps 1-2 run too), no question
#   setup/setup-git.sh work       only the work profile
#   setup/setup-git.sh all        both profiles, no question
#   setup/setup-git.sh check      show what is set up, change nothing
# Every step shows what is already there and asks before changing anything, so running it
# again is safe. Guide (Vietnamese): docs/plan.md, "Môi trường phát triển" -> "1. Git".
#
# Result for each profile P (personal, work):
#   ~/Documents/P/                 repos of that account live here
#   ~/.gitconfig-P                 user.name / user.email of that account
#   ~/.gitconfig                   includeIf "gitdir:~/Documents/P/" -> ~/.gitconfig-P
#   ~/.ssh/id_ed25519_P            SSH key of that account (with a passphrase)
#   ~/.ssh/config                  Host github-P -> github.com with that key only
# Clone with the alias, inside the folder: git clone git@github-P:OWNER/REPO.git ~/Documents/P/REPO
#
#   1 Packages        git, openssh
#   2 Defaults        init.defaultBranch main, core.editor nano
#   3 Folder + identity (per profile)
#   4 SSH key + alias (per profile)
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

PROFILES=(personal work)
CHECK=0
case "${1:-ask}" in
    ask)
        # One account keeps the machine simple (no work folder, key or alias); two keeps
        # work repos and their commits apart from personal ones
        printf '%sGit setup%s: which GitHub accounts on this machine?\n' "$B" "$N"
        printf '   1) One account: personal only  (~/Documents/personal)\n'
        printf '   2) Two accounts: personal + work  (~/Documents/personal, ~/Documents/work)\n'
        read -r -p "   Choose 1 or 2 [1]: " choice
        case "${choice:-1}" in
            1) PROFILES=(personal) ;;
            2) PROFILES=(personal work) ;;
            *) echo "   Nothing chosen, stopped." >&2; exit 2 ;;
        esac
        ;;
    all) ;;
    check) CHECK=1 ;;
    personal|work) PROFILES=("$1") ;;
    *) echo "usage: setup-git.sh [personal|work|all|check]   (no argument: asks 1 or 2 accounts)" >&2; exit 2 ;;
esac
# GitHub's published ed25519 host key fingerprint (docs.github.com, "GitHub's SSH key
# fingerprints"): compare it with what ssh shows the first time it connects
GITHUB_FP="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"
SSH_CONFIG="$HOME/.ssh/config"

printf '%sGit setup%s %s(profiles: %s%s)%s\n' "$B" "$N" "$D" "${PROFILES[*]}" \
    "$([ "$CHECK" = 1 ] && echo ', check only')" "$N"

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
    DIR="$HOME/Documents/$P"
    IDFILE="$HOME/.gitconfig-$P"
    KEY="$HOME/.ssh/id_ed25519_$P"
    HOST="github-$P"

    step 3 "Folder and identity · $P"
    if [ -d "$DIR" ]; then good "Folder ~/Documents/$P"
    elif [ "$CHECK" = 1 ]; then warn "Folder ~/Documents/$P is missing"
    elif ask "Create ~/Documents/$P?"; then mkdir -p "$DIR" && good "Created ~/Documents/$P"
    fi

    name=$(git config -f "$IDFILE" --get user.name 2>/dev/null || true)
    email=$(git config -f "$IDFILE" --get user.email 2>/dev/null || true)
    if [ -n "$name" ] && [ -n "$email" ]; then
        good "Identity in ~/.gitconfig-$P: $name <$email>"
    fi
    if [ "$CHECK" = 0 ] && { [ -z "$name" ] || [ -z "$email" ] || ask "Change the $P identity?"; }; then
        info "The name and email shown on commits of the $P account (GitHub email or its"
        info "noreply address from github.com/settings/emails)."
        name=$(prompt "Name" "$name")
        email=$(prompt "Email" "$email")
        if [ -n "$name" ] && [ -n "$email" ]; then
            git config -f "$IDFILE" user.name "$name"
            git config -f "$IDFILE" user.email "$email"
            good "Saved to ~/.gitconfig-$P"
        else
            warn "Name or email empty: identity not saved."
        fi
    elif [ "$CHECK" = 1 ] && { [ -z "$name" ] || [ -z "$email" ]; }; then
        warn "No identity in ~/.gitconfig-$P"
    fi

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

    step 4 "SSH key and alias · $P"
    if [ -f "$KEY" ]; then
        good "Key ~/.ssh/id_ed25519_$P ($(ssh-keygen -lf "$KEY.pub" 2>/dev/null | awk '{print $2}'))"
    elif [ "$CHECK" = 1 ]; then
        warn "No key ~/.ssh/id_ed25519_$P"
    elif ask "Create the SSH key ~/.ssh/id_ed25519_$P?"; then
        info "ssh-keygen asks for a passphrase: choose one (you type it on every push;"
        info "no ssh-agent on this machine). Enter twice."
        mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "${email:-$P}" -f "$KEY" && good "Key created"
    fi

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

    step 5 "GitHub · $P"
    if [ "$CHECK" = 1 ]; then
        info "Test by hand: ssh -T git@$HOST"
        continue
    fi
    if [ ! -f "$KEY.pub" ]; then
        warn "No public key yet: skipped."
        continue
    fi
    if ask "Show the public key to add it on GitHub (account: $P)?"; then
        info "Sign in to GitHub with the $P account, open github.com/settings/ssh/new,"
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
            good "GitHub knows this key ($P)."
        else
            bad "Not connected: check the key on GitHub and the alias, then run this step again."
        fi
    fi
done

printf '\n%s━━ Done%s\n' "$B$C" "$N"
for P in "${PROFILES[@]}"; do
    info "$P: clone with  git clone git@github-$P:OWNER/REPO.git ~/Documents/$P/REPO"
done
info "Check later: setup/setup-git.sh check"
