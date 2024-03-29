################################################
# kubectl / kubernetes / k8s helpers
################################################
function set_pod_name() {
  export pod_name=$(k get po | fzf --header-lines=1 | awk '{ print $1 }')
}

function az_aks_get_all {
  az aks list | jq '.[] | "\(.name) \(.resourceGroup)"' -r | xargs -n2 zsh -c 'az aks get-credentials --resource-group $2 --name $1 --admin --overwrite-existing' zsh
}

function k8sUniqueContainers() {
  kubectl get pods -o jsonpath="{..image}" |\
    tr -s '[[:space:]]' '\n' |\
    sort |\
    uniq -c
}

function k3d_get_all_configs() {
  output_dir=${1:-~/.kube}
  echo output_dir=${output_dir}
  k3d cluster ls
  k3d cluster ls --no-headers \
    | awk '{print $1}' \
    | xargs -I % zsh -lc "k3d kubeconfig get % > ${output_dir}/k3d_%_ctx"
  ls -lh ${output_dir} | grep k3d
}
alias k=kubectl
alias s=switch # used to help with switching contexts and namespaces
alias sni="switch --no-index" # do not use cached values
alias sk="s ns; k9"
alias snsk="s ns; k9"
alias sns="kc_app_k9s_select_ns"
alias kn="kubens"
alias knc="kubens -c"
alias azi="az interactive"

# setup helm
alias hd='helm delete'
alias hl='helm ls'
alias hla='helm ls -a'

# short for kgpt
function kg() {
  [[ -z "${1}" ]] || yes_flag="-yes"
  echo "Enter your kubectl gpt query: "
  read query
  kubectl gpt "${yes_flag}" "${query}"
}
alias kgg="kg y"


# set interval on k9s to 1 second
function k9() {
  k9s --headless -n $(knc) -r 1
}
alias k9a='k9s -r 1 -A --headless'
alias kk="k9"
alias ka="k9a"
function kaf() {
   arr=("$@")
   for i in "${arr[@]}"; do
     kubectl apply -f ${i}
   done
}
function kdf() {
   arr=("$@")
   for i in "${arr[@]}"; do
     kubectl delete -f ${i}
   done
}
function k_select_resource() {
  # dne load resource list
  resource_list=${kc_tmp_dir}/resources_list
  [[ -s ${resource_list} ]] || kc_app_resources_load
  resource_type=$(cat ${resource_list} | fzf +m -0)
  [[ "" == "${resource_type}" ]] && return || echo ${resource_type}
}
# k9s + select resource
alias kkrf="kkr f"
alias kkraf="kar f"
function kkr() {
  [[ "" != "${1}" ]] && unset k9s_resource_type
  [[ "" == ${k9s_resource_type} ]] && export k9s_resource_type=$(k_select_resource | tr -d "[:blank:]")
  k9s --headless -n $(knc) -r 1 -c ${k9s_resource_type}
}
# k9s all + select resource
function kar() {
  [[ "" != "${1}" ]] && unset k9s_resource_type
  [[ "" == ${k9s_resource_type} ]] && export k9s_resource_type=$(k_select_resource | tr -d "[:blank:]")
  k9s --headless -n $(knc) -r 1 -c ${k9s_resource_type} -A
}
alias kwai='clear; kubectl config get-contexts; echo kube_config=$KUBECONFIG; ll ~/.kube/config; hla'
alias kcc='env | grep KUBECONFIG | xargs -I % echo "export %" | tbc_load kube' # copies kube config variable into tmux buffer
alias kcp='tbc_paste kube' # used in tmux keytable
################################################

## smart completions - kc ######################
################################################
export kc_tmp_dir=/tmp/kc
function kc() {
  clear
  items=(
    k9s
    resources
    context
    auth
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf)
  kc_app_${choice}
}
function kc_app_context() {
  items=(
    cp
    clean
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf)
  kc_app_context_${choice}
}
function kc_app_context_clean() {
  echo deleting ${kc_tmp_dir} files:
  ll ${kc_tmp_dir}
  rm -f ${kc_tmp_dir}/*
}
function kc_app_context_cp() {
  original_kubeconfig=${KUBECONFIG}
  resolved_kubeconfig=${original_kubeconfig:-~/.kube/config}
  mkdir -p ${kc_tmp_dir}

  ns=$(_select_ns)
  ctx_name=$(k config current-context)
  file=$(mktemp ${kc_tmp_dir}/${ctx_name}_${ns}.XXXXX)
  cp -L ${resolved_kubeconfig} ${file} # follow the link

  export KUBECONFIG=${file}
  _set_ns ${ns}
  kwai
}

function kc_app_auth() {
  items=(
    aks_self
    aks_admin
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf)
  kc_app_auth_${choice}
}

function kc_app_auth_aks_self() {
  subscription=$(az account list --all | jq -r '.[].name' | fzf --prompt="select a subscription: " +m)
  az account set --subscription=${subscription}
  az aks list \
    | jq '.[] | "\(.name) \(.resourceGroup)"' -r \
    | fzf --with-nth=1 --prompt="select a cluster: " \
    | xargs -n2 zsh -c 'az aks get-credentials -n ${1} -g ${2} -f ~/.kube/${1}_ctx --overwrite-existing --format exec' zsh
}

function kc_app_auth_aks_admin() {
  subscription=$(az account list --all | jq -r '.[].name' | fzf --prompt="select a subscription: " +m)
  az account set --subscription=${subscription}
  az aks list \
    | jq '.[] | "\(.name) \(.resourceGroup)"' -r \
    | fzf --with-nth=1 --prompt="select a cluster: " \
    | xargs -n2 zsh -c 'az aks get-credentials -n ${1} -g ${2} -f ~/.kube/${1}_admin_ctx --overwrite-existing --admin' zsh
}

function kc_app_resources() {
  items=(
    load
    clear
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf)
  kc_app_resources_${choice}
}

function kc_app_resources_clear() {
  rm ${kc_tmp_dir}/resources_list
}
function kc_app_resources_load() {
  mkdir -p ${kc_tmp_dir}
  resources=$(k api-resources)# > ${kc_tmp_dir}/resources_list
  str=$(echo ${resources} | head -1)
  substr="KIND"
  prefix=${str%%$substr*}
  index=${#prefix}
  # take from KIND col, and from second row on - omit header
  echo ${resources} | cut -c${index}- | tail -n +2 | tr '[:upper:]' '[:lower:]' > ${kc_tmp_dir}/resources_list
}
function kc_app_k9s() {
  items=(
    resource
    ns_resource
    select_ns
    new_ctx_ns_cp
    select_primary_kube_ctx
    select_primary_work_ctx
    select_kube_ctx_cp
    select_work_ctx_cp
    multi_kube_ctx
    multi_work_ctx
    allns_resource
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf --prompt="select k9s a helper: ")
  kc_app_k9s_${choice}
}

function _set_ns() {
  ns=${1}
  kubectl config set-context --current --namespace=${ns} > /dev/null 2>&1
}

function _select_ns() {
  ns=$(kubectl get ns -o json  | jq -r '.items[].metadata.name' | fzf -0 --prompt "namespace: ")
  echo ${ns}
}

function kc_app_k9s_select_ns() {
  _set_ns $(_select_ns)
}
function kc_app_k9s_new_ctx_ns_cp() {
  kc_app_context_cp
  kcc
}
function kc_app_k9s_ns_resource() {
  _set_ns $(_select_ns)
  kc_app_k9s_resource
}
function kc_app_k9s_resource() {
  kkr
}
function kc_app_k9s_allns_resource() {
  kar
}
function kc_app_k9s_select_primary_kube_ctx() {
  tmux send "ks kube " Tab
}
function kc_app_k9s_select_primary_work_ctx() {
  cd ~/.work_ctx
  tmux send "ks local " Tab
}
function kc_app_k9s_select_kube_ctx_cp() {
  # C-Space - ignores globalalias expansion
  tmux send "export KUBECONFIG=\"\$(ks kube --pipe" C-Space ")\"" C-Space "&& kcc" Left Left Left Left Left Left Left Left Left Tab
}
function kc_app_k9s_select_work_ctx_cp() {
  cd ~/.work_ctx
  # C-Space - ignores globalalias expansion
  tmux send "export KUBECONFIG=\"\$(ks local --pipe" C-Space ")\"" C-Space "&& kcc" Left Left Left Left Left Left Left Left Left Tab
}
function kc_app_k9s_multi_kube_ctx() {
  tmux send "ks kube -t " Tab
}
function kc_app_k9s_multi_work_ctx() {
  cd ~/.work_ctx
  tmux send "ks local -t " Tab
}
