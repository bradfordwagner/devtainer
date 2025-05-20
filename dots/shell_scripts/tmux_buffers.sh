#!/bin/zsh
set -e

mode=$1
latest_buffer=/tmp/${USER}_latest_buffer

if [ "${mode}" = "latest" ]; then
  if [ -f ${latest_buffer} ]; then
    buffer=$(cat ${latest_buffer})
  fi
fi

if [ "${buffer}" = "" ]; then
  # ctrl-d to delete buffer and refresh the buffer list
  command='tmux list-buffers -F "#{buffer_name}:#{buffer_sample}"'
  buffer=$(eval ${command} 2>/dev/null \
      | fzf \
        --exit-0 \
        --delimiter : \
        --preview "echo {2} | bat -f --style=full -l bash" \
        --preview-window=top:50% \
        --bind 'enter:become:echo {1}' \
        --bind "ctrl-d:execute-silent(tmux deleteb -b {1})+reload:${command}" \
  )
fi

if [ "${buffer}" != "" ]; then
  if [ "${mode}" = "popup" ]; then
    buffer_contents=$(tmux show-buffer -b ${buffer})
    set -x
    eval ${buffer_contents}
  # used in grimoire ephemeral shell to quick paste
  elif [ "${mode}" = "paste" ]; then
    tmux paste-buffer -b ${buffer}
  elif [ "${mode}" = "latest" ]; then
    tmux paste-buffer -b ${buffer}
  fi
  # also paste the buffer into latest buffer
  echo "${buffer}" > ${latest_buffer}
fi
