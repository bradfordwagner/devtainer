#!/bin/zsh
set -e

# variation of fd
local dir
cd ~/workspace
dir=$(find ${1:-.} -path '*/\.*' -prune \
  -o -type d -print 2> /dev/null | fzf --exit-0)

dir_name=$(basename ${dir})
target_dir="${HOME}/workspace/$(echo ${dir} | cut -b 3-)"
tmux new-window -n ${dir_name} -c "${target_dir}"

