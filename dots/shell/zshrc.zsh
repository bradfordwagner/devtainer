# enable the following for profiling
# zmodload zsh/zprof

export TERM="xterm-256color"

# zap config
# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
plug "Aloxaf/fzf-tab"
plug "paulirish/git-open"
# plug "zap-zsh/zap-prompt"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-completions"
plug "zsh-users/zsh-syntax-highlighting"

# vi mode
bindkey -v

# https://github.com/junegunn/fzf/issues/257 - select all support
# tokyo night theme for fzf
# https://github.com/folke/tokyonight.nvim/issues/60#issue-909006048
export FZF_DEFAULT_OPTS="-m --bind ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all,ctrl-s:toggle "'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#ffffff,bg+:#1a1b26,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'
zstyle ':fzf-tab:*' fzf-flags ${(Q)${(Z:nC:)FZF_DEFAULT_OPTS}} # https://github.com/Aloxaf/fzf-tab/pull/479#discussion_r1794558759

export BAT_THEME="TwoDark"

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

# load shell interactive components
[ -f ~/workspace/github/shell/github.shell.tmuxinator/completion/tmuxinator.zsh ] && source ~/workspace/github/shell/github.shell.tmuxinator/completion/tmuxinator.zsh

if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi
autoload -Uz compinit && compinit
compdef kubecolor=kubectl
# complete -o nospace -C /opt/homebrew/bin/vault vault

[ -f ~/.dotfiles/dots/shell/bindkey.zsh ] && source ~/.dotfiles/dots/shell/bindkey.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export jump_dir_editor_cmd="v"

# enable the following for profiling
# zprof

# i can't figure out where /usr/bin is being added again, and we want homebrew first
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# load starship
eval "$(starship init zsh)"
