################################################
# force a UTF-8 locale
################################################
# A bare container (Coder pod) starts with LANG/LC_* completely unset, which
# leaves LC_CTYPE=POSIX. tmux then marks the client as non-UTF-8
# (`tmux list-clients -F '#{client_utf8}'` reports 0) and substitutes every
# multibyte glyph, so nerd-font icons in the status bar / starship / nvim come
# out as placeholders. nvim, less and sort mis-handle multibyte input the same way.
# C.UTF-8 is built into glibc, so it needs no locale-gen and survives a pod
# rebuild that wipes `/`. macOS has no C.UTF-8, hence the split.
if [[ -z ${LC_ALL} && -z ${LC_CTYPE} && -z ${LANG} ]]; then
  if [[ $OSTYPE == darwin* ]]; then
    export LANG=en_US.UTF-8
  else
    export LANG=C.UTF-8
  fi
fi

################################################
# setup PATH
################################################
export GOPATH="${HOME}/go"
export GOBIN="${GOPATH}/bin"
export GINKGO_EDITOR_INTEGRATION=true # allow unit tests coverage to run in focus mode
export GORACE=history_size=7
export ACK_GINKGO_DEPRECATIONS=1.16.4 # stop the annoying deprecation popups

export VAULT_FORMAT=json         # set default vault output format

export ARGOCD_GRPC_MAX_SIZE_MB=1000 # increase the max size of the grpc request

export PATH=~/bin:~/.rd/bin:/usr/local/bin:$PATH
export PATH=$PATH:$GOBIN
export PATH=$PATH:/opt/local/bin:/bin:/usr/local/bin:/usr/bin:/sbin:/usr/sbin:/opt/local/sbin
export PATH=$PATH:~/shell_scripts
export PATH=$PATH:~/.dotfiles/dots/shell_scripts
export PATH=$PATH:~/.dotfiles/dots/shell_scripts/speed
export PATH=$PATH:~/.krew/bin # kubectl plugins
export PATH=$PATH:${HOME}/.local/bin

################################################
export WATCH_INTERVAL=1
################################################

function printColors {
T='TiP'   # The test text

echo -e "\n                 40m     41m     42m     43m\
     44m     45m     46m     47m";

for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
           '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
           '  36m' '1;36m' '  37m' '1;37m';
  do FG=${FGs// /}
  echo -en " $FGs \033[$FG  $T  "
  for BG in 40m 41m 42m 43m 44m 45m 46m 47m;
    do echo -en "$EINS \033[$FG\033[$BG  $T  \033[0m";
  done
  echo;
done
echo
}
