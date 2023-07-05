# tmux buffers completion - helpers
export tbc_dir="${HOME}/.tbc"

function tbc() {
  clear
  items=(
    paste
    create_category
    delete_category
    clear_category
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf --prompt="tmux buffer: ")
  tbc_${choice}
}

function tbc_create_category() {
  # read a category from the user
  vared -p 'Enter Category Name: ' -c category
  mkdir -p ${tbc_dir}
  echo "0" > ${tbc_dir}/${category}
}
function tbc_delete_category() {
  category=$(tbc_get_category ${1})
  tbc_clear_category
  rm -rf ${tbc_dir}/${category}
}
function tbc_clear_category() {
  category=$(tbc_get_category ${1})
  # delete all buffers which match the name
  tmux list-buffers -F "#{buffer_name}" \
    | grep ${category} \
    | awk '{print $1}' \
    | xargs -I % tmux deleteb -b %
  echo "0" > ${tbc_dir}/${category}
}
function tbc_list() {
  ls ${tbc_dir}
}

# this function is used to load data into tbc for consumption
# there really isn't a way to use the fancy completion here
# so it will need to be manually referenced
function tbc_load() {
  category=$(tbc_get_category ${1})
  read buffer
  index=$(cat ${tbc_dir}/${category})
  echo ${buffer} | tmux loadb -b ${category}-${index} -

  # increment
  index=$((index+1))
  echo ${index} > ${tbc_dir}/${category}
}
function tbc_paste() {
  buffer_name=$(tbc_get_buffer_name ${1})
  tmux pasteb -b ${buffer_name}
}

function tbc_get_category() {
  category=${1}
  # if category is empty
  if [[ -z ${category} ]]; then
    # read a category from the user
    category=$(tbc_list | fzf --prompt="select a category: ")
  fi
  echo ${category}
}

function tbc_get_buffer_name() {
  category=$(tbc_get_category ${1})
  command=$(printf 'tmux list-buffers -F "#{buffer_name}:#{buffer_sample}" | grep %s' ${category})
  eval ${command} \
    | fzf \
      --exit-0 \
      --delimiter=":" \
      --with-nth=2 \
      --bind "enter:become:echo {1}" \
      --bind "ctrl-d:execute-silent(tmux deleteb -b {1})+reload(${command})"
}
