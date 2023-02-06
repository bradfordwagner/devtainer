#!/bin/zsh
set -e

dir="${0%/*}/speed" # get script dir
echo dir=${dir}
selected=$(find "$dir/" -maxdepth 1 -type f -exec basename {} '.sh' \; | sort | fzf -e -i --prompt="fzf-speed: " --info=default --layout=reverse)
eval "${dir}/${selected}.sh"

