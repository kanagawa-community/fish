#!/usr/bin/env bash
# Render assets/screenshots/<variant>.png from a real fish session.
#
# fish runs in a headless tmux pane with each theme applied. The script types a
# short session, captures the pane with its colors, recolors the 16 terminal
# colors from the shared palette and renders the result with freeze.
#
# Requires: fish, tmux, eza, freeze, python3, curl, and the FiraCode Nerd Font.
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

# A fixed home directory, so every run draws the same listing.
demo="$work/home/kanagawa-community/fish"
mkdir -p "$demo"/{.git,assets,themes}
printf x >"$demo/.editorconfig"
head -c 1100 /dev/zero | tr '\0' x >"$demo/LICENSE"
head -c 2800 /dev/zero | tr '\0' x >"$demo/README.md"
touch -d '2026-11-07 11:13' "$demo"/{.git,assets,themes,.editorconfig,LICENSE,README.md}

send() {
  tmux -L kanagawa-preview send-keys -t s -l "$1"
  [[ ${2:-} == noenter ]] || tmux -L kanagawa-preview send-keys -t s Enter
  sleep 0.7
}

for variant in wave dragon lotus; do
  bg=$(python3 -I - "$work/palette.json" "$variant" <<'PY'
import json, sys
colors = json.load(open(sys.argv[1]))["variants"][sys.argv[2]]["colors"]
print(next(c["hex"] for c in colors.values() if "ui.bg" in c["usage"]))
PY
)
  tmux -L kanagawa-preview kill-server 2>/dev/null || true
  tmux -L kanagawa-preview new-session -d -s s -x 100 -y 22 -c "$work/home" \
    -e XDG_CONFIG_HOME="$work/xdg" -e HOME="$work/home" -e COLORTERM=truecolor \
    -e TERM=xterm-256color -e LC_ALL=C \
    "fish --no-config -C 'source $root/scripts/fixtures/prompt.fish; fish_config theme choose \"Kanagawa ${variant^}\" >/dev/null; clear'"
  sleep 1.5
  send 'colors'
  send 'cd kanagawa-community/fish'
  send 'eza --all --long --group-directories-first --color=always --icons=always --no-user'
  send 'nosuchcommand --flag' noenter
  tmux -L kanagawa-preview capture-pane -p -e -t s \
    | python3 -I "$root/scripts/ansi16.py" "$work/palette.json" "$variant" \
    | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}' >"$work/$variant.ansi"
  freeze --language ansi --background "$bg" --padding 24 --margin 0 --window=false \
    --border.radius 0 --font.family "$font" --font.size 16 --line-height 1.4 \
    --output "$root/assets/screenshots/$variant.png" <"$work/$variant.ansi"
done
