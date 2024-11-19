#!/bin/zsh
# set -e

echo saving buffers

buffer_names=$(tmux list-buffers -F "#{buffer_name}")

mkdir ~/.tmux 2> /dev/null
buffer_file=~/.tmux/buffers.txt
echo -n "" > ${buffer_file}
for buffer in $(echo ${buffer_names}); do
  encoded_buffer=$(tmux show-buffer -b ${buffer} | base64)
  echo "${buffer} ${encoded_buffer}" >> ${buffer_file}
done

# echo buffer file:
bat -P ${buffer_file}

# wait for input
echo -n "Press enter to continue"
read 
