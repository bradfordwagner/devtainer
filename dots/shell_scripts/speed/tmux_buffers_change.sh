#!/bin/zsh

echo ${palette_red}Change Buffers${palette_restore}

# mkdir tmux with silent error
buffers_dir=~/.tmux
cd ${buffers_dir}
mkdir ${buffers_dir} 2> /dev/null
buffer_file=${buffers_dir}/buffers.txt

selected_buffer_file=$(ls ${buffers_dir}/*.txt | fzf +m -0 --prompt="select a buffer: " --preview 'bat -lproperties -P {}')
[[ "" == "${selected_buffer_file}" ]] && return || echo ${selected_buffer_file}
rm ${buffer_file}
ln -s ${selected_buffer_file} ${buffer_file}

~/.dotfiles/dots/shell_scripts/speed/tmux_buffers_load.sh
