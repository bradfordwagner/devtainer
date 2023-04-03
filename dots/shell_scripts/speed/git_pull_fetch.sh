#!/bin/zsh
set -e

# all windows in the session are renumbered in sequential order, respecting the base-index option.
tmux send "g pull; g fetch -p" Enter

