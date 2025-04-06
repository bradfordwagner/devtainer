#!/bin/zsh

# theme=~/.config/rofi/launchers/type-3/style-3.rasi
theme=~/.config/rofi/launchers/type-1/style-10.rasi
# theme=~/.config/rofi/launchers/type-2/style-7.rasi
open -a Xquartz
(jdl) \
  | rofi -dmenu -i -p ">" -theme ${theme} \
  | xargs -I {} zsh -lc 'cd {} && ih'
