#!/bin/zsh
set -e

mode=$1

# ctrl-d to delete buffer and refresh the buffer list
command='tmux list-buffers -F "#{buffer_name}:#{buffer_sample}"'
buffer=$(eval ${command} 2>/dev/null \
    | fzf \
      --exit-0 \
      --delimiter : \
      --preview "echo {2} | bat -f --style=full -l bash" \
      --bind 'enter:become:echo {1}' \
      --bind "ctrl-d:execute-silent(tmux deleteb -b {1})+reload:${command}" \
)

if [ "${buffer}" != "" ]; then
  if [ "${mode}" = "popup" ]; then
    buffer_contents=$(tmux show-buffer -b ${buffer})
    set -x
    eval ${buffer_contents}
  elif [ "${mode}" = "paste" ]; then
    tmux paste-buffer -b ${buffer}
  fi
fi
