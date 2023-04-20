#!/bin/zsh

items=(
  append
  new
)
choice=$(printf "%s\n" "${items[@]}" | fzf --prompt "overwrite/append state? > ")

state_file=~/workspace/github/bradfordwagner/src/bradfordwagner.src.cheatsheet/state.md
if [[ "new" == "${choice}" ]]; then
  echo "# State" > ${state_file}
fi

window_name=$(tmux display-message -p '#W')
delay=1
echo "## ${window_name}" >> ${state_file}

echo -n "- current_dir=" >> ${state_file}
tmux send "pwd >> ${state_file}" Enter; sleep ${delay}

echo -n "- git_branch=" >> ${state_file}
tmux send "git branch --show-current >> ${state_file}" Enter; sleep ${delay}

tmux send "bat -P ${state_file}" Enter
