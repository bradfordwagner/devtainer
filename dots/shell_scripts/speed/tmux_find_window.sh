#!/bin/zsh
set -e

window_name=$(tmux list-windows -F '#{window_index} #{window_name}' | fzf | awk '{print $1}')
tmux select-window -t ${window_name}
