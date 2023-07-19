#!/bin/zsh
set -e

# https://github.com/junegunn/fzf/wiki/examples#tmux
session=$(tmux list-sessions -F '#{session_id}:#{session_name}' 2>/dev/null \
  | fzf --exit-0 --delimiter=":" --with-nth=2 --preview="tmux list-windows -t {1}"
)
tmux switch-client -t ${session}

