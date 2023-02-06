#!/bin/zsh
set -e

# https://github.com/junegunn/fzf/wiki/examples#tmux
session=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | fzf --exit-0)
echo session=${session}
tmux switch-client -t ${session}

