#!/bin/zsh

theme=~/.config/rofi/launchers/type-1/style-10.rasi # dmenu
theme=~/.config/rofi/launchers/type-4/style-2.rasi  # centered launcher
open -a Xquartz
(jdl) \
  | rofi -dmenu -i -p ">" -theme ${theme} \
  | xargs -I {} zsh -lc 'cd {} && ih'
