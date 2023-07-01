#!/bin/zsh
set -e

# ctrl-d to delete buffer and refresh the buffer list
buffer=$(tmux list-buffers -F "#{buffer_name}: #{buffer_sample}" 2>/dev/null \
    | fzf --exit-0 --preview "echo {} | sed 's/.*://' | bat -f --style=full -l bash" \
    --bind "ctrl-d:execute-silent(echo '{}' | sed 's/:.*//' | tmux deleteb -b)+reload(tmux list-buffers -F \"#{buffer_name}: #{buffer_sample}\")" \
    | sed 's/:.*//'
)
[ "${buffer}" != "" ] && tmux paste-buffer -b ${buffer}
