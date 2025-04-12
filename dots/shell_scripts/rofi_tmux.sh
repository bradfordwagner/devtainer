#!/bin/zsh

theme=~/.config/rofi/launchers/type-1/style-10.rasi # dmenu
theme=~/.config/rofi/launchers/type-4/style-2.rasi  # centered launcher
prompt='tmux>'

# tmux list all sessions and windows in format "session:window"
open -a Xquartz
res=$(tmux list-windows -a -F '#{session_name}:#{window_index}:#{window_name}' \
  | rofi -dmenu -i -theme ${theme} -p ${prompt}
)

# if res is empty return
if [ -z "$res" ]; then
  return
fi
alacritty -e zsh -lc "tmux_zap ${res}"
