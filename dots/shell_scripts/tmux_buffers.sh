#!/bin/zsh
set -e

buffer=$(tmux list-buffers -F "#{buffer_name}: #{buffer_sample}" 2>/dev/null | fzf --exit-0 --preview "echo {} | sed 's/.*://' | bat -f --style=full -l bash" | sed 's/:.*//')
[ "${buffer}" != "" ] && tmux paste-buffer -b ${buffer}

