set -x

layer=${1}

# colors
[[ "${layer}" == "insert" ]] && color=magenta
[[ "${layer}" == "base" ]] && color=brightyellow
[[ "${layer}" == "speed" ]] && color=brightmagenta
[[ "${layer}" == "resize" ]] && color=brightblue
[[ "${layer}" == "kube" ]] && color=red

# active border
# bg=default to make it a thin bar, bg=${color} to make it a full bar
border_style="bg=default fg=${color}"
[[ ${layer} == "insert" ]] && border_style="bg=default fg=${color}"
tmux set -g pane-active-border-style "${border_style}"

# set status left color
standard_status_color="#[fg=green]"
#{?pane_synchronized, #[bg=blue]SYNC!!!#[default],}
tmux set -g status-left "${standard_status_color}kt=[#[fg=${color}]#{client_key_table}${standard_status_color}] ws=[#{?pane_synchronized,#[fg=brightred]sync#[fg=green],no_sync}] "

# keytables/layers
[[ "${layer}" == "base" ]] && key_table=b
[[ "${layer}" == "resize" ]] && key_table=r
[[ "${layer}" == "kube" ]] && key_table=k
[[ "${layer}" == "speed" ]] && key_table=s
[[ "${layer}" == "insert" ]] && key_table=root

# set key-table for all existing sessions
# -g does not work as of tmux 3.3a
tmux list-sessions -F "#{session_name}" \
  | xargs -I % tmux set -t % key-table ${key_table}

