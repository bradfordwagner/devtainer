#!/bin/zsh

theme=~/.config/rofi/launchers/type-1/style-10.rasi # dmenu
theme=~/.config/rofi/launchers/type-4/style-10.rasi  # dmenu round
theme=~/.config/rofi/launchers/type-4/style-1.rasi  # centered launcher
prompt='jump_idea>'
open -a Xquartz
(jdl) \
  | rofi -dmenu -i -theme ${theme} -p ${prompt} \
  | xargs -I {} zsh -lc 'jumpdir addweight "{}" && cd {} && ih'
