alias resource='source ~/.zprofile'
alias x=exit
alias nb=newsboat

################################################
# git aliases
################################################
function lazygit() {
    git add --all
    echo provide a commit message
    read commit_msg
    git commit -a -m "$commit_msg"
    git push
}
function lazyGitCommit() {
  local msg=$1
  git add .
  git commit -m "$msg"
}
# lazy git select
function lgs() {
  files=$(git status -s | awk '{print $2}' | fzf -m --preview="git diff {} | delta") || return
  echo $files | xargs -I {} git add {}
  echo provide a commit message
  read commit_msg
  git commit -m "${commit_msg}"
  git push
}
function git_restore() {
  git status -s | awk '{print $2}' | fzf -m --preview="git diff {} | delta" | xargs -I {} git restore {}
}
alias g=git
alias ga='git add'
alias gb='git branch'
alias gc='git clean -fd'
alias gcm='git commit -m'
alias gd='git diff'
alias glh="git ll | nl -v1 | sed 's/^ \+/&HEAD~/' | head -n 25" # git log head
alias glt='git log --tags --oneline --simplify-by-decoration --date-order --date=short --expand-tabs --color=always --no-walk --reverse --pretty=format:"%Cblue%ad (%cr)|%Cred%ae|%Cgreen%D" | column -t -s "|"'
alias gp='git push'
alias gpf='git push -f'    # git push force
alias gr=git_restore
alias grd='cd $(git root)' # git root directory
alias grh='git reset --hard' # git reset hard
alias grv='git remote -v'
alias gs='git status -s'
alias gss='git switch'
alias gsd='clear; gs; gd'
alias lg=lazygit
alias lgc=lazyGitCommit;
function git_tag() {
  tag=${1}
  if [ -z "$tag" ]; then
    echo ${palette_lcyan}Latest Tags:${palette_restore}
    git tag -l | sort -V | tail -n 5 | sort -V
    # git sv: https://github.com/bvieira/sv4git
    echo -n "${palette_lcyan}current_version = " && git sv cv
    echo -n "${palette_lgreen}next_version =  " && git sv nv

    # breaking change
    items=(
      yes
      manual
    )
    use_next_version=$(printf "%s\n" "${items[@]}" \
     | fzf --exit-0 --height=4 --prompt="use next_version? "
    )
    if [[ "${use_next_version}" == "yes" ]]; then
      tag=$(git sv nv)
    else
      echo -n "tag: "
      read tag
    fi

    if [ -z "$tag" ]; then
      echo "No tag provided"
      return
    fi

    echo tag=${tag}
    echo ${tag} | pbcopy
  fi
  git tag ${tag}
  git push origin --tags
}
alias gt='git tag'
################################################

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
# fd - cd to selected directory
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
function fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | \
                   fzf)
  cd "$dir"
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
alias go_watch_test='watchexec -cr -f "*.go" -- go test ./...'
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
  clear
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
  tmux send "c && task -t ${taskfile} ${task_name}" Tab
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
################################################

## ai aliases ##################################################
alias gg='gh copilot suggest'
## end ai aliases ##############################################
