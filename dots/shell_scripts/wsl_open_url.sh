#!/usr/bin/env bash
# tmux-fzf-url opener for WSL (@fzf-url-open). explorer.exe exits 1 on success and drains
# stdin, killing the plugin's multi-select loop; </dev/null and exit 0 are both load-bearing.

for url in "$@"; do
    explorer.exe "$url" </dev/null &>/dev/null
done

exit 0
