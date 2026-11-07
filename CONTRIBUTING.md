# Contributing to Kanagawa for fish

Thanks for helping. This port follows the
[Kanagawa community contributing guide](https://github.com/kanagawa-community/.github/blob/main/.github/CONTRIBUTING.md),
which explains conventional commits, the checks every pull request runs, and how
changes are reviewed. This page covers only what is specific to this port.

## Where to report what

- Problems with the theme in fish, such as wrong colors, poor
  contrast, or a missing variant, belong in this repository's
  [issue tracker](https://github.com/kanagawa-community/fish/issues).
- Problems in fish itself belong with its maintainers, not here. Start
  from the [application's page](https://fishshell.com).
- Changes to the colors themselves belong in the
  [shared palette](https://github.com/kanagawa-community/.github/blob/main/PALETTE.md),
  not in this port. Open an issue in the
  [.github repository](https://github.com/kanagawa-community/.github/issues)
  so every port stays in step.

## Colors

Take colors from the shared [palette](https://github.com/kanagawa-community/.github/blob/main/PALETTE.md)
and follow the [style guide](https://github.com/kanagawa-community/.github/blob/main/STYLE-GUIDE.md).
Do not sample colors from screenshots or add new ones. Every change must work in
Wave, Dragon, and Lotus.

To read the colors from a script, use the machine-readable
[palette.json](https://raw.githubusercontent.com/kanagawa-community/.github/main/palette.json).

## Working on this port

The themes in `themes/` are plain fish theme files, one per variant. Each line
sets one fish color variable to a palette color, chosen by role. The README lists
the mapping. To try a change, copy the files to `~/.config/fish/themes/` and run
`fish_config theme choose "Kanagawa Wave"` (or Dragon, Lotus) in a new shell.

The images in `assets/screenshots/` are rendered, not captured by hand. After
changing a theme, run `scripts/render-previews.sh` and commit the new images. It
needs `fish`, `tmux`, `eza`, [freeze](https://github.com/charmbracelet/freeze)
and the FiraCode Nerd Font. See the
[preview standard](https://github.com/kanagawa-community/.github/blob/main/PREVIEWS.md).

## Pull requests

- Keep each pull request to one change, and include a screenshot of each variant
  it affects.
- Update the README when installation or usage changes.
