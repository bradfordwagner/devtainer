# _ij_open_file: open file in intellij
function _ij_open_file() {
  local file=$1
  local line=$2
  if [ -n "$line" ]; then
    eval idea --line $line $file
  else
    eval idea $file
  fi
}

# _ij_search: search files and open in intellij
function ij_search() {
  local wd=$1
  local file=$2

  cd ${wd}
  items=(
    live
    input
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf)
  echo choice=$choice

  if [ $choice = "input" ]; then
    echo -n "search: "
    read input
    choice=live
  fi


  res=$(_ij_search_${choice} ${input})
  echo res=$res
  if [ -n "$res" ]; then
    file=$(echo $res | awk -F: '{print $1}')
    line=$(echo $res | awk -F: '{print $2}')
    _ij_open_file $file $line
  fi
}

# sub function of _ij_search_ - _ij_search_live: search live and open in intellij
function _ij_search_live() {
  local input=$1
  echo $(git grep --line-number "${input}" |
    fzf --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window +{2}-/2
  )
}

# _ij_search_file: search current file and opens in intellij
function ij_search_file() {
   local wd=$1
   local file=$2
   # prior to awk output=filename:lineNumber:lineContent
   line=$(grep -nH "" "$file" \
     | fzf --delimiter :  \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window +{2}-/2 \
     | awk -F: '{print $2}'
   )
  _ij_open_file $file $line
}

# Modified version where you can press
#   - CTRL-O to open with open,
#   - CTRL-V to open with vim,
#   - Enter key to open with the idea
function ij_open_file() {
  local wd=$1
  cd ${wd}
  files=$(git ls-files)
  IFS=$'\n' out=("$(echo ${files} | fzf --preview 'bat --color "always" {}' --exit-0 --expect=ctrl-o,ctrl-e,ctrl-c,esc)") # no preview
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)

  echo key=${key},file=${file}
  cmd=""
  if [ -n "$file" ]; then
    # enter
    [ "${key}" = "" ]     && cmd="idea $file"
    [ "${key}" = ctrl-o ] && cmd="open $file"
    [ "${key}" = ctrl-c ] && cmd=""
    [ "${key}" = esc ]    && cmd=""
    echo cmd=${cmd}
    if [ "${cmd}" = "" ]; then
      return
    fi
    eval ${cmd}
  fi
#  fo
}

function ij_open_file_v2() {
  open -a XQuartz
  theme=~/.config/rofi/launchers/type-4/style-2.rasi
  # default to current directory
  local wd=${1:-$(pwd)}
  # find all files in version control
  cd ${wd}
  git ls-files \
   | rofi -dmenu -i -p "Open file" -no-fixed -width 1000 -columns 1 -lines 10 -theme ${theme} \
   | xargs -I {} sh -c 'idea {}'
}
