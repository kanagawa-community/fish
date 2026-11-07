# Preview hook for .github/scripts/render-previews.sh: fish runs in a headless
# tmux pane with each theme applied, a short session is typed, and the pane is
# captured with its colors. The session follows docs/PREVIEWS.md.
# Requires: fish, tmux, eza, fastfetch, rsync.
# shellcheck shell=bash
name=fish

setup() {
  mkdir -p "$work/xdg/fish/themes"
  cp "$root"/themes/*.theme "$work/xdg/fish/themes/"
  # The listing shows this repository's own files, copied into a fixed home
  # directory with one timestamp, so only the file names and sizes change.
  demo="$work/home/kanagawa-community/$(basename "$root")"
  mkdir -p "$demo"
  rsync -a --exclude=.git "$root"/ "$demo"/
  mkdir "$demo/.git"
  find "$demo" -exec touch -h -d '2026-11-07 11:13' {} +
}

cleanup() {
  tmux -L kanagawa-preview kill-server 2>/dev/null || true
}

send() {
  tmux -L kanagawa-preview send-keys -t s -l "$1"
  [[ ${2:-} == noenter ]] || tmux -L kanagawa-preview send-keys -t s Enter
  sleep 0.7
}

capture() {
  cleanup
  sleep 0.5
  tmux -L kanagawa-preview new-session -d -s s -x 100 -y 34 -c "$demo" \
    -e XDG_CONFIG_HOME="$work/xdg" -e HOME="$work/home" -e COLORTERM=truecolor \
    -e TERM=xterm-256color -e LC_ALL=C -e PREVIEW_VARIANT="$1" \
    "fish --no-config -C 'source $root/scripts/fixtures/prompt.fish; fish_config theme choose kanagawa-$1 >/dev/null; clear'"
  sleep 1.5
  send 'fastfetch -l none -s colors'
  send 'echo "Hi, $USER" '"'"'from'"'"' $(basename $PWD) | tr A-Z a-z && ls *.md > /dev/null || echo no # comment'
  send 'eza -alF --icons --group-directories-first --no-user'
  send 'nosuchcommand --flag'
  send 'fastfetch ' noenter
  tmux -L kanagawa-preview capture-pane -p -e -t s >"$2"
}
