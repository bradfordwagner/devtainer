export tmux_actions_dir=~/.tmux_actions_dir

# entrypoint
function tq() {
  item=$1
  if [[ "" == "${item}" ]]; then
    items=(
      get
      add
      edit
      list
      clear
      source
    )
    item=$(printf "%s\n" "${items[@]}" | fzf --prompt="select a helper: ")
  fi
  [[ "" == "${item}" ]] && return

  # invoke
  _tq_${item}
}

function _tq_get() {
  dir=$(cat ${tmux_actions_dir} | fzf)
  echo ${dir}
}

function _tq_edit() {
  ${EDITOR} ${tmux_actions_dir}
}

function _tq_add() {
  current_dir=$(pwd)
  # prompt user for a name save in dir_name variable
  current_basename=$(basename ${current_dir})
  echo -n "Enter a name for the directory (default=${current_basename}): "
  read dir_name
  # if dir_name is empty, use the current directory name
  [[ "" == "${dir_name}" ]] && dir_name=${current_basename}

  echo "export tq_${dir_name}=${current_dir}" >> ${tmux_actions_dir}
}

function _tq_list() {
  bat -P ${tmux_actions_dir}
}

function _tq_source() {
  source ${tmux_actions_dir}
}

function _tq_clear() {
  echo -n "" > ${tmux_actions_dir}
}
