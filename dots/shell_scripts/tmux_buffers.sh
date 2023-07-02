#!/bin/zsh
set -e

# ctrl-d to delete buffer and refresh the buffer list
command='tmux list-buffers -F "#{buffer_name}: #{buffer_sample}"'
buffer=$(eval ${command} 2>/dev/null \
    | fzf --exit-0 \
      --delimiter : \
      --preview "echo {2} | bat -f --style=full -l bash" \
      --bind "ctrl-d:execute-silent(tmux deleteb -b {1})+reload:${command}" \
    | sed 's/:.*//'
)
[ "${buffer}" != "" ] && tmux paste-buffer -b ${buffer}
