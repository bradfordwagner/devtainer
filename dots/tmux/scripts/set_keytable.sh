set -ex

layer=${1}

# colors
typeset -A colors=()
colors[insert]=magenta
colors[base]=brightyellow
colors[speed]=brightmagenta
colors[resize]=brightblue
colors[kube]=red
color=${colors[$layer]}

# active border
border_style="bg=${color} fg=${color}"
[[ ${layer} == "insert" ]] && border_style="bg=${color} fg=${color}" # bg=default to make it a thin bar
tmux set -g pane-active-border-style "${border_style}"

# set status left color
standard_status_color="#[fg=green]"
#{?pane_synchronized, #[bg=blue]SYNC!!!#[default],}
tmux set -g status-left "${standard_status_color}kt=[#[fg=${color}]#{client_key_table}${standard_status_color}] ws=[#{?pane_synchronized,#[fg=brightred]sync#[fg=green],no_sync}] "

# keytables/layers
typeset -A layers=()
layers[base]=b
layers[resize]=r
layers[kube]=k
layers[speed]=s
layers[insert]=root
key_table=${layers[${layer}]}
# set key-table for all existing sessions
# -g does not work as of tmux 3.3a
tmux list-sessions -F "#{session_name}" \
  | xargs -I % tmux set -t % key-table ${key_table}

