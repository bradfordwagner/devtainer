#!/bin/bash
choice=$(printf '34" screen\nlaptop extra small\nlaptop small\nlaptop medium\nlaptop large' | fzf --prompt="Display: " --height=~10)

case "$choice" in
  '34" screen')          swaymsg "output X11-1 resolution 3440x1440 position 0 0 scale 1.0" ;;
  'laptop extra small')  swaymsg "output X11-1 resolution 2496x1664 position 0 0 scale 1.0" ;;
  'laptop small')        swaymsg "output X11-1 resolution 2496x1664 position 0 0 scale 1.2" ;;
  'laptop medium')       swaymsg "output X11-1 resolution 2496x1664 position 0 0 scale 1.4" ;;
  'laptop large')        swaymsg "output X11-1 resolution 2496x1664 position 0 0 scale 1.6" ;;
esac
