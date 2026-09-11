#!/usr/bin/env bash
set -uo pipefail

SAVE_DIR="$HOME/Pictures/Capturas"
mkdir -p "$SAVE_DIR"
FILE="$SAVE_DIR/complete-image-$(date '+%Y-%m-%d_%H-%M-%S').png"

grim "$FILE" || { notify-send -u critical "Error"; exit 1; }

timeout 0.25 slurp >/dev/null 2>&1

wl-copy --type image/png < "$FILE"
notify-send "Captura completa guardada" "$FILE" -i "$FILE"
paplay ~/.local/share/sounds/notify.wav > /dev/null 2>&1 &
