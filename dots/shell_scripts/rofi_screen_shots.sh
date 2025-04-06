#!/bin/zsh

open -a Xquartz

# doesnt work quite yet
theme=~/.config/rofi/launchers/type-3/style-6.rasi
ls ~/screenshots/ | while read A ; do  echo -en "$A\x00icon\x1f~/screenshots/$A\n" ; done \
  | rofi -dmenu -i -p ">" -theme ${theme} -show-icons \
  | xargs -I {} pbcopy < "~/screenshots/{}"

