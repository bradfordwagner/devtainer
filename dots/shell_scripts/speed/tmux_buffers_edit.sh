#!/bin/zsh


# mkdir tmux with silent error
mkdir ~/.tmux 2> /dev/null
buffer_file=~/.tmux/buffers.txt

${EDITOR} ${buffer_file}

# load buffers after making changes
~/.dotfiles/dots/shell_scripts/speed/tmux_buffers_load.sh
