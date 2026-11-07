#!/usr/bin/env bash
# Render assets/screenshots/<variant>.png from scripts/sample.fish.
# Requires: fish, freeze (https://github.com/charmbracelet/freeze), python3, curl.
# Follows https://github.com/kanagawa-community/.github/blob/main/PREVIEWS.md
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
palette=${PALETTE_JSON:-https://raw.githubusercontent.com/kanagawa-community/.github/main/palette.json}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/xdg/fish/themes" "$root/assets/screenshots"
cp "$root"/themes/*.theme "$work/xdg/fish/themes/"
if [[ $palette == http* ]]; then curl -fsSL "$palette" -o "$work/palette.json"; else cp "$palette" "$work/palette.json"; fi

for variant in wave dragon lotus; do
  name="Kanagawa ${variant^}"
  bg=$(python3 -I - "$work/palette.json" "$variant" <<'PY'
import json, sys
colors = json.load(open(sys.argv[1]))["variants"][sys.argv[2]]["colors"]
print(next(c["hex"] for c in colors.values() if "ui.bg" in c["usage"]))
PY
)
  XDG_CONFIG_HOME="$work/xdg" HOME="$work/home" fish -c \
    "fish_config theme choose '$name' >/dev/null; fish_indent --ansi < '$root/scripts/sample.fish'" \
    | freeze --language ansi --background "$bg" --padding 24 --margin 0 \
        --window=false --border.radius 0 --font.size 16 --line-height 1.4 \
        --output "$root/assets/screenshots/$variant.png"
done
