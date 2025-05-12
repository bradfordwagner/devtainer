#!/bin/zsh

layout=${1:-"floating"} # floating|tiling
aerospace list-windows --workspace focused | awk '{print $1}' | xargs -I {} aerospace layout ${layout} --window-id {}
