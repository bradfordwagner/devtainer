#!/bin/zsh
set -e

# https://github.com/junegunn/fzf/wiki/examples#tmux
window=$(tmux list-windows -F "#{window_index}:#{window_name}" 2>/dev/null | fzf --exit-0 | sed 's/:.*//')
echo window=${window}
tmux selectw -t ${window}

