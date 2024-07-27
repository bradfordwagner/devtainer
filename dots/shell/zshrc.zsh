# enable the following for profiling
# zmodload zsh/zprof

# export ZSH=$HOME/.oh-my-zsh
export TERM="xterm-256color"

# zap config
# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
# plug "zap-zsh/supercharge"
plug "Aloxaf/fzf-tab"
plug "paulirish/git-open"
plug "zap-zsh/zap-prompt"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"

# Load and initialise completion system
# autoload -Uz compinit
# compinit


# https://github.com/junegunn/fzf/issues/257 - select all support
# tokyo night theme for fzf
# https://github.com/folke/tokyonight.nvim/issues/60#issue-909006048
export FZF_DEFAULT_OPTS="-m --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all,ctrl-s:toggle "'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#ffffff,bg+:#1a1b26,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'

export BAT_THEME="TwoDark"

# export ZSH_THEME="agnoster"
# export plugins=(
#   fzf-tab
#   git-open
#   vi-mode
#   globalias
# )
# ignore case for globalias
GLOBALIAS_FILTER_VALUES=(grep)

# avoid duplications in history
# https://unix.stackexchange.com/questions/599641/why-do-i-have-duplicates-in-my-zsh-history
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# setup man color: https://www.2daygeek.com/get-display-view-colored-colorized-man-pages-linux/
export LESS=-R
export LESS_TERMCAP_mb=$'\E[01;31m' \
export LESS_TERMCAP_md=$'\E[01;38;5;74m' \
export LESS_TERMCAP_me=$'\E[0m' \
export LESS_TERMCAP_se=$'\E[0m' \
export LESS_TERMCAP_so=$'\E[30;43m' \
export LESS_TERMCAP_ue=$'\E[0m' \
export LESS_TERMCAP_us=$'\E[04;38;5;146m' \

# export GITSTATUS_LOG_LEVEL=DEBUG

# load oh my zsh
# source $ZSH/oh-my-zsh.sh

# load shell interactive components
[ -f ~/workspace/github/shell/github.shell.tmuxinator/completion/tmuxinator.zsh ] && source ~/workspace/github/shell/github.shell.tmuxinator/completion/tmuxinator.zsh

if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
else
    echo no fzf installed!
fi

# enable fzf tab completions
# enable-fzf-tab

if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi
autoload -Uz compinit && compinit
compdef kubecolor=kubectl
# complete -o nospace -C /opt/homebrew/bin/vault vault

# double source this.. yuck. its mostly to override some of the zsh defaults like "l", and "ll"
[ -f ~/.dotfiles/dots/shell/alias.zsh ] && source ~/.dotfiles/dots/shell/alias.zsh

# bind keys
export KEYTIMEOUT=0.7 # default is 0.4
# register functions for bindkey
zle -N alacritty_transparency_enable
zle -N alacritty_transparency_disable
# note \M- is used for meta
# we can also use a modal mode for sequence of binds
export jump_dir_editor_cmd="v"
bindkey -s '\C-kj' 'v\n'
bindkey -s '\C-kk' 'kc_app_k9s\n'
bindkey '\C-kd' fzf-cd-widget
bindkey -s '\C-ksd' 'jd \n'
bindkey -s '\C-ksj' 'jdv \n'
bindkey -s '\C-ksk' 'wfd \n'
bindkey '\C-kte' alacritty_transparency_enable
bindkey '\C-ktd' alacritty_transparency_disable
bindkey -s '\C-kl' 'task \t'
bindkey -s '\C-k\C-l' ' && task \t'
bindkey -s '\C-k\C-k' 'taskfiles\n'
bindkey -s '\C-k\C-s' 'gsd\n' # give git status
bindkey -s '\C-kj' ' | jq' # give git status

# enable the following for profiling
# zprof

# load starship
eval "$(starship init zsh)"
