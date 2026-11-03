#!/usr/bin/env bash
# copy a pane's full scrollback into a new tmux buffer and the system clipboard.
# usage: copy_pane.sh [pane-id]   (defaults to the active pane)
#
# load-buffer -w hands the text to the outer terminal via OSC 52 (set-clipboard
# is "external"), so it reaches the clipboard on macOS, sway and over ssh alike.
# -J joins wrapped lines; trailing blank lines (unused screen rows) are dropped.

target=${1:-}

tmux capture-pane -p -J -S - ${target:+-t "${target}"} \
  | perl -0pe 's/\n+\z/\n/' \
  | tmux load-buffer -w -

lines=$(tmux show-buffer | wc -l | tr -d ' ')
tmux display "copied ${lines} lines from pane ${target:-current}"
