# yt-x extension (loaded through CONFIG_AUTOLOADED_EXTENSIONS in ../../config):
# show the preview of the first video as soon as it is ready.
#
# yt-x writes the per-video preview scripts and downloads the thumbnails in the
# background while fzf is already open. fzf draws the first preview at once, before
# either is there, and only draws again when the selection moves, so the first item
# stayed empty until you went down and back up.
# Here fzf listens on a Unix socket (--listen), and both background jobs ask it to
# redraw the preview (refresh-preview) when they finish.

YT_X_FZF_SOCK="${XDG_RUNTIME_DIR:-/tmp}/yt-x-fzf-$$.sock"
CONFIG_FZF_OPTS="$CONFIG_FZF_OPTS
  --listen=$YT_X_FZF_SOCK"

_yt_x_refresh_preview() {
  [ -S "$YT_X_FZF_SOCK" ] || return 0
  curl -s --max-time 2 --unix-socket "$YT_X_FZF_SOCK" -X POST http://localhost \
    -d 'refresh-preview' >/dev/null 2>&1
}

# Same as yt-x's _preview_fzf (0.8.x), with a refresh after each background job
_preview_fzf() {
  while IFS= read -r line; do
    if [ "$CONFIG_ENABLE_PREVIEW" = "true" ]; then
      printf '%s/%s.sh|%s\n' "$CLI_PREVIEW_SCRIPTS_DIR" "$(printf '%s' "$line" | _util_generate_hash)" "$line"
    else
      printf '%s\n' "$line"
    fi
  done

  local data_to_preview
  data_to_preview="$1"

  if [ "$CONFIG_ENABLE_PREVIEW" = "true" ]; then
    {
      _preview_fzf_generate_script "$data_to_preview" </dev/null
      sleep 0.2   # fzf may still be starting when this is quick
      _yt_x_refresh_preview
    } &
    if [ "$CONFIG_ENABLE_PREVIEW_IMAGES" = "true" ]; then
      {
        _preview_fzf_download_imgs "$data_to_preview" </dev/null
        _yt_x_refresh_preview
      } &
    fi
  fi
}
