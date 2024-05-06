################################################
# setup PATH
################################################
#export JAVA_HOME=${JAVA_HOME:-/usr/local/java/jdk_8u202_x64}
NODE_PATH=/usr/local/bin/node
NPM_PATH=/usr/local/bin/npm
MAVEN_PATH=/Users/bwagner/bin/apache-maven-3.6.3
ANT_PATH=/Users/bwagner/bin/apache-ant-1.8.2

GOPATH_BIN=~/go/bin
export GOPATH="${HOME}/go"
export GOBIN="${HOME}/bin"
export GINKGO_EDITOR_INTEGRATION=true # allow unit tests coverage to run in focus mode
export GORACE=history_size=7
export ACK_GINKGO_DEPRECATIONS=1.16.4 # stop the annoying deprecation popups

export VAULT_FORMAT=json         # set default vault output format

export PATH=~/bin:~/.rd/bin:/usr/local/bin:$PATH
export PATH=$PATH:$NODE_PATH
export PATH=$PATH:$NPM_PATH
#export PATH=$PATH:$JAVA_HOME/bin
export PATH=$PATH:$MAVEN_PATH/bin
export PATH=$PATH:$ANT_PATH/bin
export PATH=$PATH:$GOBIN
export PATH=$PATH:/opt/local/bin:/bin:/usr/local/bin:/usr/bin:/sbin:/usr/sbin:/opt/local/sbin
export PATH=$PATH:~/shell_scripts
export PATH=$PATH:~/Library/Python/3.7/bin
export PATH=$PATH:~/Library/Python/3.8/bin
export PATH=$PATH:~/workspace/github/shell/github.shell.powerline/scripts
export PATH=$PATH:/snap/bin   # ubuntu snaps
export PATH=$PATH:~/.krew/bin # kubectl plugins
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
