#!/bin/zsh
set -e

source ~/workspace/github/bradfordwagner/go.bin/bradfordwagner.go.bin.jumpdir.cli/hack/alias.sh
cmd=${1:-jdt}
eval ${cmd}

