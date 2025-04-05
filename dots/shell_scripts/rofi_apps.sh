#!/bin/zsh

open -a "Xquartz"
cd /Applications
ls -d *.app \
  | sed 's/\.app$//' \
  | rofi -dmenu -i -p ">" \
  | xargs -I {} open "{}.app"
