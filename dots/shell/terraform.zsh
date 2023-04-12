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

