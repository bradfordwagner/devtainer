alias resource='source ~/.zprofile'

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
alias lgc=lazyGitCommit;
alias lg=lazygit
alias gcm='git commit -m'
alias gd='git diff'
alias gs='git status -s'
alias gsl='git status'
alias gsd='clear; gs; gd'
alias glh="git ll | nl -v1 | sed 's/^ \+/&HEAD~/' | head -n 25" # git log head
alias grd='cd $(git root)' # git root directory
alias gpf='git push -f'    # git push force
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
docker run -it --platform linux/amd64 -v $(pwd):/root quay.io/bradfordwagner/ansible:3.6.2-archlinux_latest /bin/sh -l
}
function ansible_role_container() {
git clean -fd
cat > ansible.sh << EOF
[ -f meta/requirements.yml ] && ansible-galaxy install -r meta/requirements.yml || echo "Skipping Role Dependency Download: No requirements.yml Found"
set -e
ansible-playbook test.yml && echo Success || echo Failure
EOF
chmod +x ansible.sh
docker run -it -v $(pwd):/src quay.io/bradfordwagner/ansible:3.6.2-archlinux_latest /bin/sh -l -- ./ansible.sh
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
docker run -it -v $(pwd):/src --platform linux/amd64 quay.io/bradfordwagner/ansible:3.6.2-archlinux_latest /bin/sh -l
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
# web
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
# taken from fd -> vim directory
function vd() {
  fd
  nvim .
}
# taken from vd, but now using workspace
function wvd() {
  cd ~/workspace
  fd
  nvim .
}
function wgd() {
  cd ~/workspace
  fd
  git open
}
alias vh='nvim .'           # vim here
alias wcd='cd ~/workspace' # workspace cd
alias wa='watch -c -n 1 '
alias wfd='wcd; fd'

# Modified version where you can press
#   - CTRL-O to open with open,
#   - CTRL-V to open with vim,
#   - Enter key to open with the idea
fo() {
  IFS=$'\n' out=("$(fzf --query="$1" --exit-0 --expect=ctrl-o,ctrl-e,ctrl-c)") # no preview
  # IFS=$'\n' out=("$(fzf-tmux --preview 'bat --color "always" {}' --query="$1" --exit-0 --expect=ctrl-o,ctrl-e)") # with preview
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [ -n "$file" ]; then
    [ "$key" = ctrl-o ] && open "$file" || idea "$file"
    [ "$key" = ctrl-v ] && vim "${file}"
    [ "$key" = ctrl-c ] && return 0 # breakout!
  fi
  clear
  fo
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
################################################

################################################
# golang
################################################
# ginkgo watch
# this is deeply integrated with coc/vim-go
alias gopls_daemon='rm /tmp/gopls-daemon-socket; gopls -listen="unix;/tmp/gopls-daemon-socket"'
alias gw='watchexec -cr -f "*.go" "ginkgo --race --cover"'
alias gwr='watchexec -cr -f "*.go" "ginkgo --race --cover -r"'
alias go_watch_test='watchexec -cr -f "*.go" -- go test ./...'
# ginkgo run
alias gr="clear; ginkgo --race --cover"
alias grr="clear; ginkgo --race --cover -r"
alias grv="clear; ginkgo --race --cover -v"
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
################################################

################################################
# other
################################################
alias runSocat='echo starting socat on port 2333; socat -v tcp-l:2333,fork exec:"/bin/cat"'
alias c=clear
################################################

################################################
# vim
alias vim=nvim
alias v=nvim
alias vs='[[ -f session.vim ]] && nvim -S session.vim || nvim'
function vimLoadPlugins() {
  # add these commands to devtainer startup
  # after link shell - because init vim is required
  nvim +silent +PlugInstall +qall
  nvim +silent +PluginInstall +qall
  # in shell as in arch needs to be installed by root
  npm install -g bash-language-server
  # nvim +slient +VimEnter +PlugInstall +qall
  # nvim +slient +VimEnter +PluginInstall +qall
  vim +slient +VimEnter +PlugInstall +qall
  vim +slient +VimEnter +PluginInstall +qall
}

function vimClearSWP() {
  find . -name "*.swp" -delete
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
function dockerCleanImages() {
  docker rmi $(docker images -a -q)
}

function dockerSettings() {
  sudo nvim ~/Library/Group\ Containers/group.com.docker/settings.json
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
alias cl="pwp | tr -d '\n' | tmux loadb -"
################################################

## proto #######################################
alias pt='prototool'
################################################

alias m='make'
alias t='task'

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
function alacritty_transparency_disable() {
 alacritty msg config -w -1 window.opacity=1
}

function alacritty_transparency_enable() {
  alacritty msg config -w -1 window.opacity=.8
}

function mac_toggle_menubar() {
  osascript <<END
tell application "System Events"
	tell dock preferences to set autohide menu bar to not autohide menu bar
end tell
END
}
################################################
