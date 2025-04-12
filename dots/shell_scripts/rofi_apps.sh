#!/bin/zsh

theme=~/.config/rofi/launchers/type-1/style-10.rasi # dmenu
theme=~/.config/rofi/launchers/type-4/style-2.rasi  # centered launcher
prompt='app>'
open -a Xquartz
(cd /Applications && ls -d *.app; cd ~/Applications/ && ls -d *.app; cd /System/Applications/ && ls -d *.app) \
  | sed 's/\.app$//' \
  | rofi -dmenu -i -theme ${theme} -show-icons -p ${prompt} \
  | xargs -I {} open -a "{}"
