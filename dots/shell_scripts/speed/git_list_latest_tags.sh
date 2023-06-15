#!/bin/zsh
set -e

tmux send "g tag -l | sort -V | tail -n 5 | sort -V -r | nvim -" Enter

