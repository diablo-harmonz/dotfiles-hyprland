#!/usr/bin/env bash
# Claude Code status line: folder · git branch · model · context bar with percent.
# Claude Code pipes a JSON description of the session on stdin.
input=$(cat)

j() { jq -r "$1" <<<"$input" 2>/dev/null; }

dir=$(j '.workspace.current_dir // .cwd // empty')
model=$(j '.model.display_name // .model.id // empty')
session=$(j '.session_id // empty')

# Context used: the field when this version sends it, otherwise the last assistant
# message's token usage from the transcript against the window size
pct=$(j '.context_window.used_percentage // empty')
if [[ -z $pct ]]; then
    transcript=$(j '.transcript_path // empty')
    size=$(j '.context_window.context_window_size // empty')
    [[ -z $size ]] && { [[ $(j '.model.id') == *1m* ]] && size=1000000 || size=200000; }
    if [[ -r $transcript ]]; then
        used=$(tail -n 400 "$transcript" | jq -s -r '
            [ .[] | select(.type == "assistant" and .message.usage != null) ] | last
            | .message.usage
            | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
        ' 2>/dev/null)
        [[ $used =~ ^[0-9]+$ ]] && pct=$(( used * 100 / size ))
    fi
fi
pct=${pct%%.*}

# Git branch of the folder (no locks, so it never gets in git's way)
branch=""
if [[ -n $dir ]]; then
    branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null)
fi

# Colours
dim=$'\e[2m'; reset=$'\e[0m'; cyan=$'\e[36m'; magenta=$'\e[35m'
green=$'\e[38;2;78;201;176m'; yellow=$'\e[33m'; red=$'\e[31m'  # green is jade (#4ec9b0)

out="${cyan}${dir/#$HOME/\~}${reset}"
[[ -n $branch ]] && out+="  ${magenta} ${branch}${reset}"
[[ -n $model ]] && out+="  ${model}"
if [[ -n $pct ]]; then
    (( pct > 100 )) && pct=100
    if   (( pct >= 80 )); then colour=$red
    elif (( pct >= 50 )); then colour=$yellow
    else colour=$green; fi
    # [█████░░░░░░] style: used part in solid colour, the rest the same colour dimmed
    # (built in bash: tr is byte-based and breaks multi-byte characters such as █)
    width=12; filled=$(( (pct * width + 50) / 100 ))
    (( pct > 0 && filled == 0 )) && filled=1
    used_bar="" free_bar=""
    for (( i = 0; i < filled; i++ )); do used_bar+="█"; done
    for (( i = filled; i < width; i++ )); do free_bar+="█"; done
    out+="  [${colour}${used_bar}${reset}${dim}${colour}${free_bar}${reset}] ${colour}${pct}%${reset}"
fi
# Plan usage, the numbers /usage shows: 5-hour window (with its reset time) and 7 days
limit() {  # $1 = label, $2 = percent, $3 = reset epoch (optional)
    local p=${2%%.*} c=$green
    (( p >= 80 )) && c=$red || { (( p >= 50 )) && c=$yellow; }
    local s="${dim}$1${reset} ${c}${p}%${reset}"
    [[ -n $3 ]] && s+="${dim} (reset $(date -d "@$3" +%H:%M))${reset}"
    printf '%s' "$s"
}
five=$(j '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(j '.rate_limits.five_hour.resets_at // empty')
week=$(j '.rate_limits.seven_day.used_percentage // empty')
[[ -n $five ]] && out+="  $(limit 5h "$five" "$five_reset")"
[[ -n $week ]] && out+="  $(limit 7d "$week")"

[[ -n $session ]] && out+="  ${dim}${session:0:8}${reset}"
printf '%s\n' "$out"
