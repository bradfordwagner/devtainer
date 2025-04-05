#!/bin/zsh

# open -a "Xquartz" && export DISPLAY=:0 && cd /Applications; ls -d *.app | dmenu | xargs -I {} open "{}"
open -a "Xquartz"
export DISPLAY=:0
cd /Applications
ls -d *.app \
  | sed 's/\.app$//' \
  | dmenu -i \
  | xargs -I {} open "{}.app"

