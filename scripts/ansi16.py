#!/usr/bin/env python3
"""Recolor terminal output with the shared palette.

Reads ANSI text on stdin and writes it to stdout with the 16 terminal colors
replaced by the palette's term.* roles and the default foreground replaced by
ui.fg, so the renderer needs no theme of its own.

usage: ansi16.py PALETTE_JSON VARIANT < in > out
"""
import json, re, sys, os
pal = json.load(open(sys.argv[1]))
colors = pal["variants"][sys.argv[2]]["colors"]
order = ["black","red","green","yellow","blue","magenta","cyan","white"]
names = order + ["bright_"+n for n in order]
role = {u: c["hex"] for c in colors.values() for u in c["usage"]}
rgb = []
for n in names:
    h = role["term."+n].lstrip("#"); rgb.append(tuple(int(h[i:i+2],16) for i in (0,2,4)))
FG = tuple(int(role["ui.fg"].lstrip("#")[i:i+2],16) for i in (0,2,4))
def conv(m):
    parts = m.group(1).split(";") if m.group(1) else ["0"]
    out, i = [], 0
    while i < len(parts):
        p = parts[i]
        try: n = int(p)
        except ValueError: out.append(p); i += 1; continue
        if n == 39:
            out.append("38;2;%d;%d;%d" % FG)
        elif 30 <= n <= 37 or 90 <= n <= 97 or 40 <= n <= 47 or 100 <= n <= 107:
            idx = n % 10 + (8 if n >= 90 else 0); fg = n < 40 or 90 <= n <= 97
            out.append(f"{38 if fg else 48};2;{rgb[idx][0]};{rgb[idx][1]};{rgb[idx][2]}")
        elif n in (38, 48) and i + 2 < len(parts) and parts[i+1] == "5" and int(parts[i+2]) < 16:
            r = rgb[int(parts[i+2])]; out.append(f"{n};2;{r[0]};{r[1]};{r[2]}"); i += 2
        else:
            if n in (38, 48) and i + 1 < len(parts) and parts[i+1] == "2": out += parts[i:i+5]; i += 4
            elif n in (38, 48) and i + 1 < len(parts) and parts[i+1] == "5": out += parts[i:i+3]; i += 2
            else: out.append(p)
        i += 1
    # freeze drops the foreground on attribute-only sequences such as bold or underline.
    if out and out != ["0"] and not any(o.startswith(("38", "48")) for o in out):
        out.append("38;2;%d;%d;%d" % FG)
    return "\x1b[" + ";".join(out) + "m"
h = role["ui.fg"].lstrip("#"); fg = "\x1b[38;2;%d;%d;%dm" % tuple(int(h[i:i+2],16) for i in (0,2,4))
s = re.sub(r"\x1b\[([0-9;]*)m", conv, sys.stdin.read())
s = re.sub(r"\x1b\[0?m", lambda m: fg, s)
trail = re.compile(r"(?:\s|\x1b\[[0-9;]*m)+$")
lines = [trail.sub("", l) for l in s.split("\n")]
sys.stdout.write("\n".join((fg + l) if l.strip() else "" for l in lines))
