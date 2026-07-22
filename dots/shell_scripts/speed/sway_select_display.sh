#!/bin/bash
output="X11-1"

labels=(
  '34" extra small 0.8'
  '34" small 0.9'
  '34" medium 1.0'
  '34" large 1.1'
  '34" extra large 1.2'
  'laptop extra small 1.0'
  'laptop small 1.2'
  'laptop medium 1.4'
  'laptop large 1.5'
  'laptop extra large 1.6'
)
resolutions=(
  "3440x1440"
  "3440x1440"
  "3440x1440"
  "3440x1440"
  "3440x1440"
  "2496x1664"
  "2496x1664"
  "2496x1664"
  "2496x1664"
  "2496x1664"
)
scales=(
  "0.8"
  "0.9"
  "1.0"
  "1.1"
  "1.2"
  "1.0"
  "1.2"
  "1.4"
  "1.5"
  "1.6"
)

# Finds the index of the entry matching sway's current output state, so fzf
# can default the cursor there without reordering the list (order stays
# fixed so up/down in fzf always steps one size at a time).
current_index() {
  local res scale
  read -r res scale < <(swaymsg -t get_outputs -r | jq -r --arg out "$output" \
    '.[] | select(.name == $out) | "\(.current_mode.width)x\(.current_mode.height) \(.scale)"')

  # sway reports scale as a float (e.g. 1.3999999761581421 for "1.4"), so
  # compare with a tolerance instead of exact string match.
  for i in "${!labels[@]}"; do
    if [ "${resolutions[$i]}" = "$res" ] && awk -v a="${scales[$i]}" -v b="$scale" \
      'BEGIN { exit !(a - b < 0.01 && b - a < 0.01) }'; then
      echo "$i"
      return
    fi
  done
  echo 0
}

while true; do
  # fzf's pos() bind is 1-indexed from the top of the list.
  pos=$(( $(current_index) + 1 ))
  choice=$(printf '%s\n' "${labels[@]}" | fzf --prompt="Display: " --height=100% --bind "start:pos($pos)")
  [ -z "$choice" ] && break  # Escape/Ctrl-C exits the loop

  for i in "${!labels[@]}"; do
    if [ "${labels[$i]}" = "$choice" ]; then
      swaymsg "output $output resolution ${resolutions[$i]} position 0 0 scale ${scales[$i]}"
      break
    fi
  done
done
