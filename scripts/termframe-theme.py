#!/usr/bin/env python3
"""Print a termframe theme built from the shared palette.

The background and foreground come from the ui.bg and ui.fg roles, and the 16
terminal colors from the term.* roles of the chosen variant.

usage: termframe-theme.py PALETTE_JSON VARIANT > kanagawa-VARIANT.toml
"""
import json
import sys

palette = json.load(open(sys.argv[1]))
variant = sys.argv[2]
colors = palette["variants"][variant]["colors"]
role = {use: c["hex"] for c in colors.values() for use in c["usage"]}
base = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
names = base + ["bright_" + n for n in base]

appearance = "light" if palette["variants"][variant]["appearance"] == "light" else "dark"
print(f'tags = ["{appearance}"]\n')
print("[theme.colors]")
print(f'background = "{role["ui.bg"]}"')
print(f'foreground = "{role["ui.fg"]}"')
print(f'bright-foreground = "{role["ui.fg"]}"\n')
print("[theme.colors.palette]")
for i, name in enumerate(names):
    print(f'{i} = "{role["term." + name]}"')
