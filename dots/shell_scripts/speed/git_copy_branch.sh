#!/bin/zsh
set -e

tmux send "git branch --show-current | tmux loadb -" Enter

