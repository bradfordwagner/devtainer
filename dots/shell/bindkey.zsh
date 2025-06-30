
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
  bindkey -M ${keytable} -s '^kk' 'ks\n'
  bindkey -M ${keytable} -s '^k^k' 'taskfiles\n'
  bindkey -M ${keytable} -s '^ki' 'taskfile_info\n'
  bindkey -M ${keytable} -s '^e' 'gsd\n' # give git status
  bindkey -M ${keytable} -s '^o' 'glt\n' # give git tag list
done

# edit command line in editor
autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd v edit-command-line

## pilfered globalalias ########################################
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/globalias/globalias.plugin.zsh
globalias() {
   # Get last word to the left of the cursor:
   # (z) splits into words using shell parsing
   # (A) makes it an array even if there's only one element
   local word=${${(Az)LBUFFER}[-1]}
   if [[ $GLOBALIAS_FILTER_VALUES[(Ie)$word] -eq 0 ]]; then
      zle _expand_alias
      zle expand-word
   fi
   zle self-insert
}
zle -N globalias

# space expands all aliases, including global
bindkey -M emacs " " globalias
bindkey -M viins " " globalias

# control-space to make a normal space
bindkey -M emacs "^ " magic-space
bindkey -M viins "^ " magic-space

# normal space during searches
bindkey -M isearch " " magic-space
## pilfered globalalias ########################################
