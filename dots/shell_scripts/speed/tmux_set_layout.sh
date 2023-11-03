#!/bin/zsh
set -e

# all windows in the session are renumbered in sequential order, respecting the base-index option.

items=(
  even-horizontal
  even-vertical
  main-horizontal
  main-vertical
  tiled
)
choice=$(printf "%s\n" "${items[@]}" | fzf --prompt="tmux layout> ")
tmux select-layout "$choice"

