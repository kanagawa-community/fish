#!/usr/bin/env bash
# Render assets/screenshots/<variant>.png from a real fish session.
#
# fish runs in a headless tmux pane with each theme applied. The script types a
# short session and captures the pane with its colors. termframe then renders
# the capture with a theme built from the shared palette (background, foreground
# and the 16 terminal colors), and rsvg-convert turns the SVG into a PNG.
#
# Requires: fish, tmux, eza, fastfetch, termframe, rsvg-convert, rsync, python3, curl, and
# the FiraCode Nerd Font.
# Follows https://github.com/kanagawa-community/.github/blob/main/PREVIEWS.md
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
palette=${PALETTE_JSON:-https://raw.githubusercontent.com/kanagawa-community/.github/main/palette.json}
font=${PREVIEW_FONT:-FiraCode Nerd Font Mono}
work=$(mktemp -d)
trap 'tmux -L kanagawa-preview kill-server 2>/dev/null || true; rm -rf "$work"' EXIT

if [[ $palette == http* ]]; then curl -fsSL "$palette" -o "$work/palette.json"; else cp "$palette" "$work/palette.json"; fi
mkdir -p "$root/assets/screenshots" "$work/xdg/fish/themes"
cp "$root"/themes/*.theme "$work/xdg/fish/themes/"

# The listing shows this repository's own files. They are copied into a fixed
# home directory with one timestamp, so only the file names and sizes change.
demo="$work/home/kanagawa-community/$(basename "$root")"
mkdir -p "$demo"
rsync -a --exclude=.git "$root"/ "$demo"/
mkdir "$demo/.git"
find "$demo" -exec touch -h -d '2026-11-07 11:13' {} +

send() {
  tmux -L kanagawa-preview send-keys -t s -l "$1"
  [[ ${2:-} == noenter ]] || tmux -L kanagawa-preview send-keys -t s Enter
  sleep 0.7
}

for variant in wave dragon lotus; do
  mkdir -p "$work/tf/termframe/themes"
  python3 -I "$root/scripts/termframe-theme.py" "$work/palette.json" "$variant" \
    >"$work/tf/termframe/themes/kanagawa-$variant.toml"
  mode=dark; [[ $variant == lotus ]] && mode=light
  tmux -L kanagawa-preview kill-server 2>/dev/null || true
  tmux -L kanagawa-preview new-session -d -s s -x 100 -y 30 -c "$demo" \
    -e XDG_CONFIG_HOME="$work/xdg" -e HOME="$work/home" -e COLORTERM=truecolor \
    -e TERM=xterm-256color -e LC_ALL=C -e PREVIEW_VARIANT="$variant" \
    "fish --no-config -C 'source $root/scripts/fixtures/prompt.fish; fish_config theme choose kanagawa-$variant >/dev/null; clear'"
  sleep 1.5
  send 'fastfetch -l none -s colors'
  send "fish_config theme show current"
  send 'eza -alF --icons --group-directories-first --no-user'
  tmux -L kanagawa-preview capture-pane -p -e -t s \
    | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}' >"$work/$variant.ansi"
  cols=$(python3 -I -c 'import re,sys; print(max(len(re.sub(r"\x1b\[[0-9;]*m","",l.rstrip("\n").rstrip())) for l in open(sys.argv[1])))' "$work/$variant.ansi")
  rows=$(wc -l <"$work/$variant.ansi")
  XDG_CONFIG_HOME="$work/tf" termframe --theme "kanagawa-$variant" --mode "$mode" \
    --window=false --window-shadow=false --window-margin 0 --padding 1.5 \
    --font-family "$font" --font-size 16 --line-height 1.4 \
    --width "$cols" --height "$((rows + 1))" --timeout 20 \
    --output "$work/$variant.svg" -- cat "$work/$variant.ansi"
  rsvg-convert --zoom 3 "$work/$variant.svg" -o "$root/assets/screenshots/$variant.png"
done
