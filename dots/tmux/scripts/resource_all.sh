set -x

sleep_duration=1
# use actual names not alias'd names ie, base=b, where we use 'b' to set the layer
set_keytable() {
  local -r key_table=${1}
  tmux set -t % key-table ${key_table}
}

set_keytable root


tmux setw synchronize-panes
tmux send C-z               # put processes in background
sleep ${sleep_duration}
tmux send C-c C-c           # cancel in case nothing was running
sleep ${sleep_duration}
tmux send resource Enter fg # source configs again
sleep ${sleep_duration}
tmux send Enter

sleep ${sleep_duration}
set_keytable b

tmux setw synchronize-panes
