
# argo helpers
# invoke argo commands using fzf
function ac() {
  clear
  items=(
    sync
    open_ui
    terminate
    delete
    get_values
    login
    cache_apps
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf)
  argocd_app_${choice}
}
function argocd_find_app() {
  cache=~/.ac.apps
  cat ${cache} | fzf -m --exit-0
}
function argocd_app_get_values() {
  app=$(argocd_find_app)
  o=$(argocd app get ${app} --show-params -o yaml)
  release_name=$(echo ${o} | yq '.spec.source.helm.releaseName')
  namespace=$(echo ${o} | yq '.spec.destination.namespace')
  function f() {
    echo 'action=${1:-apply}'
    echo helm template ${release_name} -n ${namespace} '.' \\
    echo ${o} \
      | yq '.spec.source.helm.parameters' -r \
      | jq '.[] | .name, .value' -r \
      | xargs -n2 zsh -lc 'echo "--set $1=\"$2\"" \\' zsh
  }
  f > test.sh
  echo '| kubectl ${action} -f -' >> test.sh
  chmod +x test.sh
  bat -P test.sh
}
function argocd_app_cache_apps() {
  cache=~/.ac.apps
  rm ${cache}
  argocd app list -o name > ${cache}
  bat ${cache}
}
## AUTH #################################################################
function argocd_app_login() {
  clear
  items=(
    local_8080
    local_30001
    blk_admin
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf --prompt="login target: ")
  argocd_app_login_${choice}
  # update cache as we've changed contexts
  argocd_app_cache_apps
}
function argocd_app_login_local_30001() {
  argocd login localhost:30001 \
  --username admin \
  --password admin1234 \
  --insecure
}
function argocd_app_login_local_8080() {
  argocd login localhost:8080 \
  --username admin \
  --password admin1234 \
  --insecure
}
function argocd_app_login_blk_admin() {
  argocd login argocd.admin.na.blkint.com --sso --insecure
}
## END AUTH #############################################################
function argocd_app_sync() {
  argocd_find_app | xargs -I % argocd app sync % --force --prune
}
function argocd_app_open_ui() {
  # argocd_server=argocd.example.com
  export argocd_server=$(argocd context | grep \* | awk '{ print $2 }')
  # parse out app name for use in ui
  # then open url which we get from the context
  argocd_find_app \
    | xargs -I % bash -c "argocd app get -o json % | jq -r '.metadata.name'" \
    | xargs -I % open https://${argocd_server}/applications/%
}
function argocd_app_terminate() {
  argocd_find_app | xargs -I % argocd app terminate-op %
}
function argocd_app_delete() {
  argocd_find_app | xargs -I % argocd app delete -y %
  argocd_app_cache_apps
}

function argo_find_workflow() {
  export argo_workflow=$(argo list | fzf | awk '{ print $1 }')
}
function argo_resubmit_workflow() {
  clear; argo resubmit ${argo_workflow} --log
}
function argo_find_workflow_logs() {
  clear; argo list | fzf | awk '{ print $1 }' | xargs -I % argo logs % -f
}
function argo_find_workflow_delete() {
  argo list | fzf | awk '{ print $1 }' | xargs -I % -n 1 -P 12 argo delete %
}
alias argo_find_workflow_resubmit="argo_find_workflow; argo_resubmit_workflow"
