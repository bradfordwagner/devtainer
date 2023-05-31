set -x

set_keytable=~/.tmux/conf/scripts/set_keytable.sh
${set_keytable} insert

sleep_duration=1

tmux setw synchronize-panes
tmux send C-z               # put processes in background
sleep ${sleep_duration}     # wait a moment for things to reset
tmux send C-c C-c           # cancel in case nothing was running
sleep ${sleep_duration}     # wait a moment for things to reset
tmux send resource Enter fg # source configs again
sleep ${sleep_duration}     # wait a moment for things to reset
tmux send Enter
tmux setw synchronize-panes

${set_keytable} base
