# Created by newuser for 5.4.2
# enable the following for profiling
# zmodload zsh/zprof

export ZSH=$HOME/.oh-my-zsh
export TERM="xterm-256color"

# https://github.com/junegunn/fzf/issues/257 - select all support
export FZF_DEFAULT_OPTS="-m --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all,ctrl-s:toggle --color dark"

export BAT_THEME="TwoDark"

# from https://github.com/romkatv/powerlevel10k#oh-my-zsh
export ZSH_THEME="agnoster"
export plugins=(
  fzf-tab
  git
  git-open
  zsh-autosuggestions
  vi-mode
)

# avoid duplications in history
# https://unix.stackexchange.com/questions/599641/why-do-i-have-duplicates-in-my-zsh-history
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# environment loads
# if [[ $(hostname -s) = nycla* ]] || [[ $(hostname -s) = NYCLA* ]] || [[ $(hostname -s) = macbook-pro ]] || [[ $(hostname -s) = nycmd* ]] || [[ $(hostname -s) = bwagner-* ]]; then
  export ZSH_THEME="powerlevel10k/powerlevel10k"
# else
#   # setup hail mary color scheme on remote
#   export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
# fi
# setup man color: https://www.2daygeek.com/get-display-view-colored-colorized-man-pages-linux/
export LESS=-R
export LESS_TERMCAP_mb=$'\E[01;31m' \
export LESS_TERMCAP_md=$'\E[01;38;5;74m' \
export LESS_TERMCAP_me=$'\E[0m' \
export LESS_TERMCAP_se=$'\E[0m' \
export LESS_TERMCAP_so=$'\E[30;43m' \
export LESS_TERMCAP_ue=$'\E[0m' \
export LESS_TERMCAP_us=$'\E[04;38;5;146m' \

# load oh my zsh
source $ZSH/oh-my-zsh.sh

# load shell interactive components
[ -f ~/workspace/github/shell/github.shell.tmuxinator/completion/tmuxinator.zsh ] && source ~/workspace/github/shell/github.shell.tmuxinator/completion/tmuxinator.zsh

if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
else
    echo no fzf installed!
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# this is auto generated - keep it
[[ ! -f ~/.dotfiles/dots/shell/p10k.zsh ]] || source ~/.dotfiles/dots/shell/p10k.zsh

# enable fzf tab completions
enable-fzf-tab

# enable the following for profiling
# zprof

autoload -U compinit; compinit

# show kube ctx always
unset POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND

