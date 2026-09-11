#!/usr/bin/env bash
set -uo pipefail

SAVE_DIR="$HOME/Pictures/Capturas"
mkdir -p "$SAVE_DIR"
FILE="$SAVE_DIR/image-selected-$(date '+%Y-%m-%d_%H-%M-%S').png"
FRAME=$(mktemp --suffix=.png)

grim -l 0 "$FRAME" || { rm -f "$FRAME"; exit 1; }

pkill -KILL -f wayfreeze 2>/dev/null

PAUSADOS=()

descongelar() {
    [ -n "${FREEZE_PID:-}" ] && kill -TERM "$FREEZE_PID" 2>/dev/null
    sleep 0.2
    pkill -KILL -f wayfreeze 2>/dev/null
    rm -f "$FRAME"
    for p in "${PAUSADOS[@]}"; do
        playerctl -p "$p" play 2>/dev/null
    done
    PAUSADOS=()
    return 0
}
trap descongelar EXIT INT TERM HUP

while read -r p; do
    if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
        playerctl -p "$p" pause 2>/dev/null && PAUSADOS+=("$p")
    fi
done < <(playerctl -l 2>/dev/null)

"$HOME/.cargo/bin/wayfreeze" --hide-cursor &
FREEZE_PID=$!

sleep 0.3

GEOMETRY=$(slurp) || exit 0
[ -z "$GEOMETRY" ] && exit 0

read -r GX GY GW GH <<< "$(tr ',x' '  ' <<< "$GEOMETRY")"
read -r MINX MINY MAXX < <(hyprctl monitors -j | jq -r '
    map(. + {lw: ((if .transform % 2 == 1 then .height else .width end) / .scale)})
    | "\(map(.x) | min) \(map(.y) | min) \(map(.x + .lw) | max)"')
IMG_W=$(magick identify -format '%w' "$FRAME")

CROP=$(awk -v gx="$GX" -v gy="$GY" -v gw="$GW" -v gh="$GH" \
           -v minx="$MINX" -v miny="$MINY" -v maxx="$MAXX" -v iw="$IMG_W" 'BEGIN {
    s = iw / (maxx - minx)
    printf "%dx%d+%d+%d", gw*s + 0.5, gh*s + 0.5, (gx-minx)*s + 0.5, (gy-miny)*s + 0.5
}')

magick "$FRAME" -crop "$CROP" +repage "$FILE" || exit 1

paplay ~/.local/share/sounds/notify.wav > /dev/null 2>&1 &

descongelar
trap - EXIT INT TERM HUP

wl-copy --type image/png < "$FILE"
notify-send "Captura guardada" "$FILE" -i "$FILE"
