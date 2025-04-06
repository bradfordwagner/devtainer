#!/bin/zsh

# theme=~/.config/rofi/launchers/type-3/style-3.rasi
# theme=~/.config/rofi/launchers/type-1/style-1.rasi
theme=~/.config/rofi/launchers/type-2/style-1.rasi
open -a Xquartz
(ls -d /Applications/*; ls -d ~/Applications/*; ls -d /System/Applications/*) \
  | rofi -dmenu -i -p ">" -theme ${theme} -show-icons \
  | xargs -I {} open "{}"
