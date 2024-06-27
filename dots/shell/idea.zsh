function search_file() {
   local wd=$1
   local file=$2
   # prior to awk output=filename:lineNumber:lineContent
   line=$(grep -nH "" "$file" \
     | fzf --delimiter :  \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window +{2}-/2 \
     | awk -F: '{print $2}'
   )
   if [ -n "$line" ]; then
     eval idea --line $line $file
   fi
}

# TODO: invoke intellij and wrap with tooling
function live_search_files() {
  git grep --line-number '' |
    fzf --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --preview-window +{2}-/2
}

# Modified version where you can press
#   - CTRL-O to open with open,
#   - CTRL-V to open with vim,
#   - Enter key to open with the idea
function fo() {
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