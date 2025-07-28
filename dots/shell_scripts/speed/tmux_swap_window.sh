#!/bin/zsh
set -e

current_session=$(tmux display -p '#S')

# list windows
current_window=$(tmux display -p '#{window_index}')
window_options_without_source=$(tmux list-windows -F '#{window_index}:#{window_name}')

# reorder window_options_without_source to put current_window first
current_option=$(echo "$window_options_without_source" | grep "^$current_window:")
other_options=$(echo "$window_options_without_source" | grep -v "^$current_window:")
window_options_without_source="$current_option\n$other_options"

# use fzf to select a window
source_window=$(echo -e "$window_options_without_source" | fzf)

# verify something was selected
if [[ -z "$source_window" ]]; then
  echo "No source window selected. Exiting."
  exit 1
fi

# remove the selected source_window from window_options_without_source
options_without_source=$(echo -e "$window_options_without_source" | grep -v "^$source_window$")

# select target window
target_window=$(echo -e "$options_without_source" | fzf)

# verify something was selected for target
if [[ -z "$target_window" ]]; then
  echo "No target window selected. Exiting."
  exit 1
fi

# swap the two windows using tmux swapw
source_index=$(echo "$source_window" | cut -d: -f1)
target_index=$(echo "$target_window" | cut -d: -f1)
tmux swap-window -s "$current_session:$source_index" -t "$current_session:$target_index"
