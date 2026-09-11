#!/usr/bin/env bash
set -uo pipefail

# Modify this to change your output directory
SAVE_DIR="$HOME/Pictures/"

mkdir -p "$SAVE_DIR"
FILE="$SAVE_DIR/complete-image-$(date '+%Y-%m-%d_%H-%M-%S').png"

grim "$FILE" || { notify-send -u critical "Error"; exit 1; }

timeout 0.25 slurp >/dev/null 2>&1

wl-copy --type image/png < "$FILE"
notify-send "Image in clipboard" "$FILE" -i "$FILE"
paplay ~/.local/share/sounds/notify.wav > /dev/null 2>&1 &
