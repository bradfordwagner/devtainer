
# bind keys
export KEYTIMEOUT=0.7 # default is 0.4
keytables=(
  viins
)
for keytable in "${keytables[@]}"; do
  # force remove ^k from the keytable in jeffreytse/zsh-vi-mode
  bindkey -r ${keytable} -s '^k'

  # implement binds
  bindkey -M ${keytable} -s '^kl' 'task \t'
  bindkey -M ${keytable} -s '^k^l' ' && task \t'
  bindkey -M ${keytable} -s '^kk' 'kc_app_k9s\n'
  bindkey -M ${keytable} -s '^k^k' 'taskfiles\n'
  bindkey -M ${keytable} -s '^e' 'gsd\n' # give git status
done

# edit command line in editor
autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd v edit-command-line
