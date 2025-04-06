#!/bin/zsh

open -a Xquartz
# (ls -d ${HOME}/screenshots/*) \
#   | rofi -dmenu -i -show-icons -p ">" \
#   | xargs -I {} open "{}"


ls ~/screenshots/ | while read A ; do  echo -en "$A\x00icon\x1f~/screenshots/$A\n" ; done | rofi -dmenu 


