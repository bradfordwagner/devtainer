#!/bin/bash
res=$(swaymsg -t get_outputs -r | jq -r '.[] | select(.name == "X11-1") | "\(.current_mode.width)x\(.current_mode.height)"')

case "$res" in
  3440x1440) swaymsg "output X11-1 scale 1.0 position 0,0" ;;
  *)         swaymsg "output X11-1 scale 1.4 position 0,0" ;;
esac
