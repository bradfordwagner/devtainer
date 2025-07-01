#!/bin/zsh

# constants
swap_workspace=Y
focused_window_file=/tmp/aerospace-focused-window.txt

current_workspace=$(aerospace list-workspaces --focused)
focused_window=$(aerospace list-windows --focused --format '%{window-id}')
if [[ -z "${focused_window}" ]]; then
  echo "swap not required. focused_window=${focused_window},current_workspace=${current_workspace},swap_workspace=${swap_workspace}"
  exit 0
fi

echo checking for focused window file: ${focused_window_file}

# if we are already focused
if [[ -f "${focused_window_file}" ]]; then
  target_workspace=$(cat ${focused_window_file})
  echo "target_workspace=${target_workspace} - found focused window file"
  rm ${focused_window_file}
  # we are replacing current focus - so put everything in target_workspace back
  # then run the standard op
  if [[ "${current_workspace}" != "${swap_workspace}" ]]; then
    move_windows=$(aerospace list-windows --workspace ${swap_workspace} --format '%{window-id}')
    echo ${move_windows} | xargs -I {} aerospace move-node-to-workspace --window-id {} ${target_workspace}
  else
    # in focused namespace, move and break
    echo target_workspace=${target_workspace} - moving windows back
    aerospace move-node-to-workspace --window-id ${focused_window} ${target_workspace}
    aerospace workspace ${target_workspace}
    return
  fi
fi

echo done

# move current window to swap_workspace
echo ${current_workspace} > ${focused_window_file}
aerospace move-node-to-workspace --window-id ${focused_window} ${swap_workspace}
    aerospace workspace ${swap_workspace}

