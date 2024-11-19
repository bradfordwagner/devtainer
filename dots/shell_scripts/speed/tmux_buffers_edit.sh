#!/bin/zsh


# mkdir tmux with silent error
mkdir ~/.tmux 2> /dev/null
buffer_file=~/.tmux/buffers.txt

${EDITOR} ${buffer_file}
