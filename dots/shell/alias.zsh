alias resource='source ~/.zshrc'
alias x=exit
alias nb=newsboat

################################################
# ansible
################################################
alias ap="ansible-playbook"
alias agi="ansible-galaxy install -r requirements.yml -v -p ./roles"
# alias ag="ansible-galaxy"
function ansible_role_container_login() {
git clean -fd
cat > ansible.sh << EOF
[ -f meta/requirements.yml ] && ansible-galaxy install -r meta/requirements.yml || echo "Skipping Role Dependency Download: No requirements.yml Found"
set -e
ansible-playbook test.yml && echo Success || echo Failure
EOF
chmod +x ansible.sh
docker run -it --platform linux/amd64 -v $(pwd):/root quay.io/bradfordwagner/ansible:3.6.2-debian_bullseye /bin/sh -l
}
function ansible_role_container() {
git clean -fd
cat > ansible.sh << EOF
[ -f meta/requirements.yml ] && ansible-galaxy install -r meta/requirements.yml || echo "Skipping Role Dependency Download: No requirements.yml Found"
set -e
ansible-playbook test.yml && echo Success || echo Failure
EOF
chmod +x ansible.sh
docker run -it -v $(pwd):/src quay.io/bradfordwagner/ansible:3.6.2-debian_bullseye /bin/sh -l -- ./ansible.sh
}
function ansible_playbook_container_login() {
git clean -fd
cat > ansible.sh << EOF
clear
set -ex
[ -f requirements.yml ] && ansible-galaxy install -r requirements.yml || echo "Dependency Download: No requirements.yml Found"
ansible-playbook playbook.yml && echo Success || echo Failure
EOF
chmod +x ansible.sh
docker run -it -v $(pwd):/src --platform linux/amd64 quay.io/bradfordwagner/ansible:3.6.2-debian_bullseye /bin/sh -l
}
function ansible_playbook_dockerfile() {
git clean -fd
cat > Dockerfile << EOF
from --platform=linux/amd64 quay.io/bradfordwagner/ansible:3.6.2-archlinux_latest
copy . /src
workdir /src
run [ -f requirements.yml ] && ansible-galaxy install -r requirements.yml || echo "Dependency Download: No requirements.yml Found"
run ansible-playbook playbook.yml && echo Success || echo Failure
EOF
docker build -t t .
}
################################################

################################################
# webdev
################################################
alias ys='yarn start'
alias yrd='yarn run dev'
alias yi='yarn install'
alias yb='yarn build'
alias yc='yarn clean'
alias yl='yarn lint'
alias yt='yarn test'
################################################

alias rsync='rsync -av --progress'

# fkill - kill process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}
# sudo fkill - kill process
sudo_fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs sudo kill -${1:-9}
  fi
}

################################################
# clipboard
################################################
if hash xsel 2>/dev/null; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi
################################################
# navigation
################################################
# copied from - https://github.com/junegunn/fzf/wiki/examples#changing-directory
if hash lsd 2>/dev/null; then
  alias l="lsd -lha"
  alias ll="lsd -lh"
else
  alias l="ls -lha"
  alias ll="ls -lh"
fi
alias fenv='env | fzf'
# file source - ie get a configuration from my super secrets environment vars
function fs() {
  file=$(find -L ~/source -type f | fzf --preview 'bat -l bash --color=always {}') || return
  source ${file}
}
alias fa="find . | fzf"
# fd - cd to selected directory
function fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | \
                   fzf)
  cd "$dir"
}

# fds - cd to selected directories with tmux split (depth 1, includes hidden)

function fds() {
  local dirs split_type selected_dirs

  local -a ignore_names
  ignore_names=(.idea)

  # Find directories at depth 1, then filter out hidden (dot) dirs and items in ignore_names
  dirs=$(find ${1:-.} -maxdepth 1 -type d -not -path '.' | sort)
  # Remove hidden directories (those beginning with .)
  dirs=$(echo "$dirs" | grep -vE '^\./\.')
  # Remove any explicitly ignored directory names
  for name in "${ignore_names[@]}"; do
    dirs=$(echo "$dirs" | grep -vE "^\./${name}$")
  done

  if [[ -z "$dirs" ]]; then
    echo "No directories found"
    return 1
  fi

  # Use fzf-tmux to select multiple directories
  selected_dirs=$(echo "$dirs" | fzf-tmux -m -p 80%,60% --prompt="Select directories (Tab to multi-select, / to select & clear): ") || return

  current_dir=$(pwd)
  current_window=$(tmux display-message -p '#I')

  # Set initial layout to tiled
  tmux select-layout -t "$current_window" tiled

  # Create tmux splits for each selected directory
  echo "$selected_dirs" | while IFS= read -r dir; do
    echo dir=${dir}
    # Always create a new vertical split for each selected directory
    tmux split-window -t "$current_window" -v -c "${current_dir}/$dir"
  done

  # Arrange panes in main-vertical layout for better organization
  tmux select-layout main-vertical
}

# fdg - automatically split tmux for dirty git directories (depth 1)
function fdg() {
  local target_dirs current_dir current_window

  # Find directories at depth 1 that are git repos with changes or on a non-default branch
  target_dirs=()
  for dir in */; do
    if [[ -d "$dir" && -d "$dir/.git" ]]; then
      cd "$dir"

      local git_status current_branch default_branch origin_head
      git_status=$(git status --porcelain 2>/dev/null)
      current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

      # Determine default branch from origin/HEAD when available; otherwise fallback to main/master
      origin_head=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
      if [[ -n "$origin_head" ]]; then
        default_branch="${origin_head#origin/}"
      else
        if git show-ref --verify --quiet refs/heads/main; then
          default_branch="main"
        elif git show-ref --verify --quiet refs/heads/master; then
          default_branch="master"
        else
          default_branch=""
        fi
      fi

      # Include if dirty OR on a non-default branch (when a default branch is known)
      if [[ -n "$git_status" || ( -n "$current_branch" && -n "$default_branch" && "$current_branch" != "$default_branch" ) ]]; then
        target_dirs+=("$dir")
      fi

      cd ..
    fi
  done

  if [[ ${#target_dirs[@]} -eq 0 ]]; then
    echo "No dirty or non-default-branch git repositories found"
    return 1
  fi

  echo "Found ${#target_dirs[@]} git repositories (dirty or non-default branch):"
  printf '  %s\n' "${target_dirs[@]}"

  current_dir=$(pwd)
  current_window=$(tmux display-message -p '#I')

  # Set initial layout to tiled
  tmux select-layout -t "$current_window" tiled

  # Create tmux splits for each matching directory
  for dir in "${target_dirs[@]}"; do
    # Create vertical splits for all directories
    tmux split-window -t "$current_window" -v -c "${current_dir}/$dir"
    tmux select-layout -t "$current_window" tiled
  done

  # Arrange panes in main-vertical layout for better organization
  tmux select-layout main-vertical
}
alias fdo='fd; open .'
alias vh='nvim .'           # vim here
alias wcd='cd ~/workspace' # workspace cd
alias wfd='wcd; fd'
alias o=open

dropbox_file() {
  tofile_dir=~/Dropbox/lisa-brad/to-file
  cabinet_dir=~/Dropbox/lisa-brad
  dirs=$(find ${cabinet_dir} -type d -not -path '*/\.*')
  for file in $(ls $tofile_dir); do
    echo file=${file}
    selected_dir=$(echo "$dirs" | fzf --height 90% --prompt "Select a directory for ${file}: ") || continue
    mv ${tofile_dir}/${file} ${selected_dir}
  done
}

# pwd alias
alias pwp='pwd -P'
alias pcd='cd `pwp`; ls -lh'
################################################


################################################
# maven helpers
################################################
alias mdt="mvn dependency:tree"
function mdti {
  local search_text=$1
  mdt -Dincludes=$search_text
}

alias mvn-test="unbuffer mvn clean test | tee ~/test.output; less ~/test.output"
################################################


################################################
# tmux aliases
################################################
# this comes from the snap installation
if hash tmux-non-dead.tmux 2>/dev/null; then
  alias tmux='tmux-non-dead.tmux'
fi
alias tc='clear && tmux clear-history'
alias mux='tmuxinator start'
alias ta='tmux attach -t'
function tns() {
  # adapted from: https://gist.github.com/jyurek/7be666a88e06f68d45cf
  if [ -z "$TMUX" ]; then
      echo not tmux
      tmux new-session -As $1 -c $(pwd)
  else
    # inside tmux
    echo in tmux
    if tmux has-session -t $1 2> /dev/null; then
      echo has session
      tmux switch-client -t $1
    else
      echo new session
      tmux new-session -ds $1 -c $(pwd)
      tmux switch-client -t $1
    fi
  fi
}
alias tn='tmux new'
alias ts='tmux ls'
function tmux_dir() { # tmux open dir
  ls | fzf | xargs -n 1 zsh -c 'index=$(tmux splitw -d -P -F "#{pane_index}"); tmux send -t ${index} "cd $0" ENTER; tmux select-layout tiled'
}
alias td=tmux_dir
alias t_edit_all="tmux list-panes -F '#{pane_index}' | awk '{print $1}' | xargs -I % tmux select-pane -e -t %"
alias t_edit_none="tmux list-panes -F '#{pane_index}' | awk '{print $1}' | xargs -I % tmux select-pane -d -t %"

# tmux get layout
function tmuxCopyLayout() {
  tmux list-windows | sed -n 's/.*layout \(.*\)] @.*/\1/p' | fzf --reverse | tmux loadb -
}

## tmux buffers ################################
# this is for saving/loading buffers
# specificallyh to edit the  backed up buffer file and edit it
function tmux_buffers_edit() {
  mkdir ~/.tmux 2> /dev/null
  buffer_file=~/.tmux/buffers.txt

  ${EDITOR} ${buffer_file}

  # load buffers after making changes
  ~/.dotfiles/dots/shell_scripts/speed/tmux_buffers_load.sh

  exit
}

# https://github.com/AleckAstan/tmux-zap/blob/cd38ada1d521c66d4e3bb3a72242b2fa2ba2ed1e/scripts/zap.sh
function tmux_zap() {
  session_window=${1} # example=edit:1:buoyshell
  # if no session window passed in return
  if [ -z "${session_window}" ]; then
    return
  fi

  # split by :, assign to session and window
  session=$(echo ${session_window} | cut -d':' -f1)
  window=$(echo ${session_window} | cut -d':' -f2)

  tmux select-window -t "${session}:${window}"
  tmux attach -t "${session}"
}
################################################

################################################
# zellij aliases
################################################
alias z=zellij
################################################

################################################
# golang
################################################
# this is deeply integrated with coc/vim-go
alias gopls_daemon='rm /tmp/gopls-daemon-socket; gopls -listen="unix;/tmp/gopls-daemon-socket"'
alias go_watch_test='watchexec -c -r -f "*.go" -- go test ./...'
function go_init_godap_properties() {
  file_name=.go_dap.properties
  cat > ${file_name} << EOF
go_main=./
go_args=
EOF
}
################################################

################################################
# idea alias
################################################
alias ih='nohup idea . > /dev/null &'
#alias ih='idea . &!' # start and disown idea
[[ $OSTYPE == 'darwin'* ]] && alias ih='reattach-to-user-namespace idea .' # idea here
alias ihx='ih; sleep 3; exit' # idea here
function wi() {         # workspace idea
  cd ~/workspace
  fd
  ih
}

function wix() {        # workspace idea exit
  wi
  exit
}

function jdi() {
  jd && ih
}
################################################

################################################
# cursor alias
################################################
alias ch='cursor .'
alias chx='cursor .; exit'
################################################

################################################
# other
################################################
alias runSocat='echo starting socat on port 2333; socat -v tcp-l:2333,fork exec:"/bin/cat"'
alias c=tc
alias vv='virsh'
################################################

## vim #########################################
alias vim=nvim
# manually invoke obsession because rebasing was overwriting the session file when using autocmd
alias v='[[ -f session.vim ]] && nvim -S session.vim +AutocommandObsession || nvim +AutocommandObsession'
function vim_clear_session() {
  find . -iname 'session.vim' -delete -print
}
################################################

################################################
# pywal
function loadBackground() {
  wal -b "#272c33" -i $1 -o ${HOME}/workspace/github/python/github.python.alaacritty.color.export/script.sh
}
################################################


################################################
# docker
################################################
function docker_clean_images() {
  docker rmi $(docker images -a -q)
}

function docker_stop_containers() {
  docker stop $(docker ps -a -q)
}

function docker_remove_containers() {
  docker rm $(docker ps -a -q)
}

alias rancher_restart='rdctl shutdown && rdctl start'
################################################


################################################
# useless text tricks
################################################
alias ttyclock='tty-clock -c -C 7 -r -f "%A, %B %d"'
alias figletTime='watch -t -n1 "date +%A%n%x%n%X|figlet -t -c"'
function ft() {
  export text=$1
  watch -t -n1 "figlet ${text}"
}
function ftc() {
  export text=$1
  watch -t -n1 "figlet -c ${text}"
}

## copy location ###############################
alias cl="pwp | pbcopy"
################################################

## proto #######################################
alias pt='prototool'
################################################

alias m='make'
alias t='task'
alias we='watchexec -c -r -i="session.vim*" --shell="zsh -l -o aliases"'
alias wa='watch -c -n 1 unbuffer'
function taskfiles() {
  taskfile=$(find -L ~/.taskfiles/tasks -name '*.yml' | fzf) || return
  taskfile_info ${taskfile}
}
function taskfile_info() {
  taskfile=${1:-./Taskfile.yml}
  task_name=$(yq -r '.tasks | to_entries[] | select(.value.internal == null or .value.internal == false) | .key' ${taskfile} | fzf) || return
  task_vars=$(yq -r ".tasks.${task_name}.vars | to_entries[] | .key + \" = \" + .value" ${taskfile}) > /dev/null 2>&1
  task_desc=$(yq -r ".tasks.${task_name}.desc" ${taskfile}) > /dev/null 2>&1
  echo ${taskfile} | bat -P --file-name="Taskfile.yml"
  echo ${task_desc} | bat -P --file-name="${task_name}.description"
  echo ${task_vars} | bat -P --file-name="${task_name}.vars" -lproperties
  tmux send "task -t ${taskfile} ${task_name}" Tab
}

# File Helpers #################################
function mkdir_date() {
    mkdir "$(date +"%Y-%m-%d")"
}

function touch_path() {
  mkdir -p "$(dirname "$1")" && touch "$1"
}
################################################

function wan_ip() {
  dig TXT +short o-o.myaddr.l.google.com @ns1.google.com
}

function git_open_ado() {
  origin=$(git remote -v | awk '{print $2}')
  if [[ ${origin} =~ ^https.* ]]; then
    git open
  else
    url=$(git remote -v | grep fetch | sed 's/.*git@ssh.dev.azure.com:v3\/\(.*\)\/\(.*\)\/\(.*\) (fetch)/https:\/\/dev.azure.com\/\1\/\2\/_git\/\3/g')
    open ${url}
  fi
}


## mac stuff ###################################
function mac_toggle_menubar() {
  osascript <<END
tell application "System Events"
	tell dock preferences to set autohide menu bar to not autohide menu bar
end tell
END
}
function mac_trust_certificate() {
  certificate=${1}
  sudo security add-trusted-cert \
    -d \
    -r trustRoot \
    -k /Library/Keychains/System.keychain \
    ${certificate}
}
################################################

## ai aliases ##################################################
alias gg='gh copilot suggest'
## end ai aliases ##############################################

################################################
# security helpers
################################################
# Decode base64url (JWT-safe) string in a portable way
function b64url_decode() {
  local input="$1"
  if [ -z "$input" ]; then
    echo "b64url_decode: missing input" >&2
    return 1
  fi
  # fix padding
  local mod=$(( ${#input} % 4 ))
  if [ $mod -eq 2 ]; then input="${input}=="; elif [ $mod -eq 3 ]; then input="${input}="; fi
  # translate URL-safe chars and decode (GNU and BSD base64 compatibility)
  local data
  data=$(printf '%s' "$input" | tr '_-' '/+')
  printf '%s' "$data" | base64 --decode 2>/dev/null || printf '%s' "$data" | base64 -D 2>/dev/null
}

# jwt_decode: decode JWT header and payload (pretty-prints with jq when available)
function jwt_decode() {
  local token="$1"
  if [ -z "$token" ]; then
    if [ -t 0 ]; then
      echo "Usage: jwt_decode <jwt>  |  echo <jwt> | jwt_decode" >&2
      return 1
    else
      token=$(cat)
    fi
  fi
  # Strip optional 'Bearer ' prefix
  token="${token#Bearer }"
  # Split into parts
  local header payload signature
  IFS='.' read -r header payload signature <<< "$token"
  if [ -z "$header" ] || [ -z "$payload" ]; then
    echo "Invalid JWT (expected header.payload[.signature])" >&2
    return 1
  fi
  echo "Header:"
  if command -v jq >/dev/null 2>&1; then
    b64url_decode "$header" | jq .
  else
    b64url_decode "$header"
  fi
  echo
  echo "Payload:"
  if command -v jq >/dev/null 2>&1; then
    b64url_decode "$payload" | jq .
  else
    b64url_decode "$payload"
  fi
  if [ -n "$signature" ]; then
    echo
    echo "Signature (base64url):"
    echo "$signature"
  fi
}
################################################
