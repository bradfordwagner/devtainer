#!/bin/zsh

# constants
current_workspace=$(aerospace list-workspaces --focused)
current_monitor=$(aerospace list-monitors --focused --format '%{monitor-id}')

# move to previous workspace/monitor and get focused workspace
prev_workspace=$(aerospace workspace-back-and-forth && aerospace list-workspaces --focused)
prev_monitor=$(aerospace list-monitors --focused --format '%{monitor-id}')

# get main monitor
#main_monitor=$(aerospace list-monitors --format '%{monitor-id}:%{monitor-is-main}' | grep -E '^.*:true' | awk -F: '{print $1}')

# print debug info of all variables we just resolved
echo "current_workspace: ${current_workspace}"
echo "current_monitor: ${current_monitor}"
echo "prev_workspace: ${prev_workspace}"
echo "prev_monitor: ${prev_monitor}"

# if current and previous monitors are the same let's bail
if [[ "${current_monitor}" == "${prev_monitor}" ]]; then
  aerospace workspace-back-and-forth
  exit 0
fi

# summon current workspace to previous monitor
aerospace move-workspace-to-monitor ${prev_monitor} --workspace ${current_workspace}
aerospace focus-monitor ${current_monitor}
aerospace summon-workspace ${prev_workspace}

# ensure our workspace-back-and-forth is correct - sometimes move-workspace-to-monitor lands at a new workspace (1 or 11 sometimes)
aerospace workspace ${current_workspace}
#aerospace workspace ${prev_workspace}
