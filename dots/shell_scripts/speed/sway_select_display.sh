#!/bin/bash
choice=$(printf '34" screen\nlaptop' | fzf --prompt="Display: " --height=~10)

case "$choice" in
  '34" screen') swaymsg "output X11-1 resolution 3440x1440 position 0 0 scale 1.0" ;;
  'laptop')     swaymsg "output X11-1 resolution 2496x1664 position 0 0 scale 1.2" ;;
esac
