#!/bin/zsh

echo ${palette_red}Loading Buffers${palette_restore}

# mkdir tmux with silent error
mkdir ~/.tmux 2> /dev/null
buffer_file=~/.tmux/buffers.txt

# iterate each line in ${buffer_file} using a for loop
if [[ -f "${buffer_file}" ]]; then
    # Iterate through each line in the file
    while IFS= read -r line; do
        read -r buffer_name encoded <<< "$line"
        decoded=$(echo ${encoded} | base64 -d)
        echo ${palette_lpurple}${buffer_name} ${palette_cyan}${decoded}${palette_restore}
        echo ${decoded} | tmux loadb -b ${buffer_name} -
    done < "${buffer_file}"
else
    echo ${palette_red}"File not found: ${buffer_file}"${palette_restore}
fi

# wait for input
echo -n "Press enter to continue"
read 
