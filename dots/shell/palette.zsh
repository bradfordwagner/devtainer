# sets up a color palette to use for colored logging if needed
# https://stackoverflow.com/questions/10466749/bash-colored-output-with-a-variable

export palette_restore=$(echo -en '\001\033[0m\002')
export palette_red=$(echo -en '\001\033[00;31m\002')
export palette_green=$(echo -en '\001\033[00;32m\002')
export palette_yellow=$(echo -en '\001\033[00;33m\002')
export palette_blue=$(echo -en '\001\033[00;34m\002')
export palette_magenta=$(echo -en '\001\033[00;35m\002')
export palette_purple=$(echo -en '\001\033[00;35m\002')
export palette_cyan=$(echo -en '\001\033[00;36m\002')
export palette_lightgray=$(echo -en '\001\033[00;37m\002')
export palette_lred=$(echo -en '\001\033[01;31m\002')
export palette_lgreen=$(echo -en '\001\033[01;32m\002')
export palette_lyellow=$(echo -en '\001\033[01;33m\002')
export palette_lblue=$(echo -en '\001\033[01;34m\002')
export palette_lmagenta=$(echo -en '\001\033[01;35m\002')
export palette_lpurple=$(echo -en '\001\033[01;35m\002')
export palette_lcyan=$(echo -en '\001\033[01;36m\002')
export palette_white=$(echo -en '\001\033[01;37m\002')

