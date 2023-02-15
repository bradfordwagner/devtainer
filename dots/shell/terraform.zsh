################################################
# terraform
################################################
alias tf=terraform
alias tg=terragrunt

function tg_find() {
  find . -type d -name ".terragrunt-cache"
}

function tg_prune() {
  find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
}

# terraform completions
# from: https://www.terraform.io/docs/cli/commands/index.html#shell-tab-completion
# these don't work all that well just yet - v0.14.3
#if [ -f /usr/local/bin/terraform ]; then
#  autoload -U +X bashcompinit && bashcompinit
#  complete -o nospace -C /usr/local/bin/terraform terraform
#fi
