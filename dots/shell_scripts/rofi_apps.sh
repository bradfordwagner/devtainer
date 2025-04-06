#!/bin/zsh

# theme=~/.config/rofi/launchers/type-3/style-3.rasi
theme=~/.config/rofi/launchers/type-1/style-10.rasi
# theme=~/.config/rofi/launchers/type-2/style-7.rasi
open -a Xquartz
(cd /Applications && ls -d *.app; cd ~/Applications/ && ls -d *.app; cd /System/Applications/ && ls -d *.app) \
  | sed 's/\.app$//' \
  | rofi -dmenu -i -p ">" -theme ${theme} -show-icons \
  | xargs -I {} open -a "{}"
