# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Created by newuser for 5.4.2
# enable the following for profiling
# zmodload zsh/zprof

export ZSH=$HOME/.oh-my-zsh
export TERM="xterm-256color"

# https://github.com/junegunn/fzf/issues/257 - select all support
# tokyo night theme for fzf
# https://github.com/folke/tokyonight.nvim/issues/60#issue-909006048
export FZF_DEFAULT_OPTS="-m --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all,ctrl-s:toggle "'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#ffffff,bg+:#1a1b26,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'

export BAT_THEME="TwoDark"

# from https://github.com/romkatv/powerlevel10k#oh-my-zsh
export ZSH_THEME="agnoster"
export ZSH_THEME="powerlevel10k/powerlevel10k"
export plugins=(
  fzf-tab
  git
  git-open
  zsh-autosuggestions
  vi-mode
  globalias
)
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
# show kube ctx always
unset POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND

# enable fzf tab completions
enable-fzf-tab

# enable the following for profiling
# zprof

if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi
autoload -Uz compinit && compinit

# double source this.. yuck. its mostly to override some of the zsh defaults like "l", and "ll"
[ -f ~/.dotfiles/dots/shell/alias.zsh ] && source ~/.dotfiles/dots/shell/alias.zsh

# bind keys
export KEYTIMEOUT=0.7 # default is 0.4
[ -f ~/.oh-my-zsh/custom/plugins/lazyshell/lazyshell.zsh ] && source ~/.oh-my-zsh/custom/plugins/lazyshell/lazyshell.zsh
bindkey '^g' __lazyshell_complete
bindkey '^e' __lazyshell_explain
# register functions for bindkey
zle -N alacritty_transparency_enable
zle -N alacritty_transparency_disable
# note \M- is used for meta
# we can also use a modal mode for sequence of binds
export jump_dir_editor_cmd="nvim -c 'GFiles'"
bindkey -s '\C-kj' 'nvim\n'
bindkey -s '\C-kk' 'kc_app_k9s\n'
bindkey '\C-kd' fzf-cd-widget
bindkey -s '\C-ksd' 'jd \n'
bindkey -s '\C-ksj' 'jdv \n'
bindkey -s '\C-ksk' 'wfd \n'
bindkey '\C-kte' alacritty_transparency_enable
bindkey '\C-ktd' alacritty_transparency_disable
bindkey -s '\C-kl' 'task \t'
bindkey -s '\C-k\C-l' ' && task \t'
bindkey -s '\C-k\C-s' 'gsd\n' # give git status
