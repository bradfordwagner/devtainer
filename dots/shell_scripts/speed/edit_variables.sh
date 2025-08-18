#!/bin/zsh
set -e

# This script edits the variables file, copying from the main variables file if it exists.
variables_local_file=~/.dotfiles/variables.local.yml
variables_file=~/.dotfiles/variables.yml

if [[ -f "${variables_file}" ]]; then
  cp ${variables_file} ${variables_local_file}
fi
${EDITOR} -p ${variables_local_file}
