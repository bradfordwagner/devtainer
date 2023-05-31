set -x

set_keytable=~/.tmux/conf/scripts/set_keytable.sh
${set_keytable} insert

sleep_duration=2

tmux setw synchronize-panes
tmux send C-Z
sleep ${sleep_duration}  # wait a moment for things to reset
tmux send resource Enter # source configs again
tmux send fg             # bring processes to fg again
sleep ${sleep_duration}  # wait a moment for things to reset
tmux send Enter
tmux setw synchronize-panes

