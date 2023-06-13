#!/bin/zsh
set -e

tmux send "g tag -l | sort -V | tail -n 5 | nvim -" Enter

