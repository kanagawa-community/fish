#!/usr/bin/env bash
# Render assets/screenshots/<variant>.png from a real fish session.
#
# fish runs in a headless tmux pane with each theme applied. The script types a
# short session and captures the pane with its colors. termframe then renders
# the capture with a theme built from the shared palette (background, foreground
# and the 16 terminal colors), and rsvg-convert turns the SVG into a PNG.
#
# The window, font and spacing come from the shared termframe config, and the
# shared compose-showcase.sh stacks the three renders into assets/showcase.png.
#
# Requires: fish, tmux, eza, fastfetch, termframe, rsvg-convert, magick, rsync,
# python3, curl, and the FiraCode Nerd Font.
# Follows https://github.com/kanagawa-community/.github/blob/main/docs/PREVIEWS.md
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
palette=${PALETTE_JSON:-https://raw.githubusercontent.com/kanagawa-community/.github/main/palette.json}
style=${TERMFRAME_CONFIG:-https://raw.githubusercontent.com/kanagawa-community/.github/main/config/termframe.toml}
work=$(mktemp -d)
trap 'tmux -L kanagawa-preview kill-server 2>/dev/null || true; rm -rf "$work"' EXIT

if [[ $palette == http* ]]; then curl -fsSL "$palette" -o "$work/palette.json"; else cp "$palette" "$work/palette.json"; fi
if [[ $style == http* ]]; then curl -fsSL "$style" -o "$work/termframe.toml"; else cp "$style" "$work/termframe.toml"; fi
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
  sleep 0.5
  tmux -L kanagawa-preview new-session -d -s s -x 100 -y 34 -c "$demo" \
    -e XDG_CONFIG_HOME="$work/xdg" -e HOME="$work/home" -e COLORTERM=truecolor \
    -e TERM=xterm-256color -e LC_ALL=C -e PREVIEW_VARIANT="$variant" \
    "fish --no-config -C 'source $root/scripts/fixtures/prompt.fish; fish_config theme choose kanagawa-$variant >/dev/null; clear'"
  sleep 1.5
  send 'fastfetch -l none -s colors'
  send 'echo "Hi, $USER" '"'"'from'"'"' $(basename $PWD) | tr A-Z a-z && ls *.md > /dev/null || echo no # comment'
  send 'eza -alF --icons --group-directories-first --no-user'
  send 'nosuchcommand --flag'
  send 'fastfetch ' noenter
  tmux -L kanagawa-preview capture-pane -p -e -t s \
    | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}' >"$work/$variant.ansi"
  cols=$(python3 -I -c 'import re,sys; print(max(len(re.sub(r"\x1b\[[0-9;]*m","",l.rstrip("\n").rstrip())) for l in open(sys.argv[1])))' "$work/$variant.ansi")
  rows=$(wc -l <"$work/$variant.ansi")
  XDG_CONFIG_HOME="$work/tf" termframe --config "$work/termframe.toml" \
    --theme "kanagawa-$variant" --mode "$mode" --title "$(basename "$root")" \
    --width "$cols" --height "$((rows + 1))" --timeout 20 \
    --output "$work/$variant.svg" -- cat "$work/$variant.ansi"
  rsvg-convert --zoom 2 "$work/$variant.svg" -o "$root/assets/screenshots/$variant.png"
done

# Stack the three renders into assets/showcase.png with the shared script.
compose=${COMPOSE_SHOWCASE:-https://raw.githubusercontent.com/kanagawa-community/.github/main/scripts/compose-showcase.sh}
if [[ $compose == http* ]]; then curl -fsSL "$compose" -o "$work/compose-showcase.sh"; compose="$work/compose-showcase.sh"; fi
shots="$root/assets/screenshots"
bash "$compose" "$shots/lotus.png" "$shots/dragon.png" "$shots/wave.png" "$root/assets/showcase.png"
