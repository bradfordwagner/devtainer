#!/bin/zsh

open -a "Xquartz"
(ls -d /Applications/*; ls -d ~/Applications/*; ls -d /System/Applications/*) \
  | rofi -dmenu -i -p ">" \
  | xargs -I {} open "{}"
