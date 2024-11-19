#!/bin/zsh
# set -e

echo ${palette_red}Saving Buffers${palette_restore}

buffer_names=$(tmux list-buffers -F "#{buffer_name}")

# mkdir tmux with silent error
mkdir ~/.tmux 2> /dev/null
buffer_file=~/.tmux/buffers.txt
echo -n "" > ${buffer_file}
for buffer_name in $(echo ${buffer_names}); do
  buffer_value=$(tmux show-buffer -b ${buffer_name})
  encoded_buffer_value=$(echo ${buffer_value} | base64)
  echo ${palette_lpurple}${buffer_name} ${palette_cyan}${buffer_value}${palette_restore}
  echo "${buffer_name} ${encoded_buffer_value}" >> ${buffer_file}
done

# echo buffer file:
bat -P ${buffer_file} -lproperties

# wait for input
echo -n "Press enter to continue"
read
