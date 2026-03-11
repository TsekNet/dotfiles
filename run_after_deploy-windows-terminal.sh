#!/bin/bash
# Deploy Windows Terminal settings from dotfiles to the Windows-side path.
# Runs after every `chezmoi apply`.

WT_DIR="/mnt/c/Users/${USER}/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
SRC="$HOME/.config/windows-terminal/settings.json"

[ -d "$WT_DIR" ] || exit 0
[ -f "$SRC" ] || exit 0

cp -f "$SRC" "$WT_DIR/settings.json"
