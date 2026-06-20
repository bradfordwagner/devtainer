#!/bin/zsh

theme=~/.config/rofi/launchers/type-1/style-5.rasi
color=~/.config/rofi/colors/catppuccin.rasi

if [ -f "$theme" ] && [ -f "$color" ]; then
  rofi -theme "$theme" -theme-str "@import \"$color\"" "$@"
elif [ -f "$theme" ]; then
  rofi -theme "$theme" "$@"
else
  rofi "$@"
fi
