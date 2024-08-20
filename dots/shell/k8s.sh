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
k_bin=kubectl
if hash kubecolor 2>/dev/null; then
  k_bin=kubecolor
fi
alias k=${k_bin}
alias kubectl=${k_bin}
alias kn="kubens"
alias knc="kubens -c"
alias sk="kc_app_k9s_select_ns; k9"
alias snsk="kc_app_k9s_select_ns; k9"
alias sns="kc_app_k9s_select_ns"
alias azi="az interactive"

# kubectl aliases
alias kgp="${k_bin} get pods"
alias kgpa="${k_bin} get pods --all-namespaces"

# helm aliases
alias hd='helm delete'
alias hl='helm ls'
alias hla='helm ls -a'


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
  resource_type=$(cat ${resource_list} | fzf +m -0 --prompt="select a resource type: ")
  [[ "" == "${resource_type}" ]] && return || echo ${resource_type}
}
# k9s + select resource
alias kkrf="kkr f"
alias kkraf="kar f"

alias kdes="kac desc"
alias kdesa="kac desc a"

alias kg="kac get"
alias kga="kac get a"

function kac() {
  # resolve action
  action=${1}
  all_flag="${2}"
  if [[ "" == "${action}" ]]; then
    action_items=(
      list
      'neat get'
      describe
      get
      edit
      delete
    )
    action=$(printf "%s\n" "${action_items[@]}" | fzf --prompt="select a verb: ")

    # force all resolution
    all_items=(
      no
      all
    )
    all_selection=$(printf "%s\n" "${all_items[@]}" | fzf --prompt="all ns?: ")
    [[ 'all' == "${all_selection}" ]] && all_flag="-A"
  fi

  # resolve scope
  [[ "" != "${all_flag}" ]] && all_flag="-A"

  # resolve resource type
  resource_type=$(k_select_resource | tr -d "[:blank:]")
  [[ "" == "${resource_type}" ]] && return

  # list does not require a selection
  if [[ 'list' == "${action}" ]]; then
    cmd="k get ${resource_type} ${all_flag}"
  # process a selection
  else
    selection=$(k get ${resource_type} ${all_flag} | fzf --header-lines=1 --prompt="select resource target: ") || return
    [[ "-A" == "${all_flag}" ]] && namespace="-n $(echo ${selection} | awk '{print $1}')"
    [[ "-A" == "${all_flag}" ]] && target=$(echo ${selection} | awk '{print $2}') || target=$(echo ${selection} | awk '{print $1}')
    cmd="k ${action} ${resource_type} ${namespace} ${target}"
  fi

  # resolve override helpers
  [[ 'neat get' == "${action}" ]] && cmd="${cmd} -oyaml | bat -lyaml -P"
  echo -n ${cmd} | tmux loadb -
  eval ${cmd}
}

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
    delete_clusters
    resources
    context
    auth
  )
  choice=$(printf "%s\n" "${items[@]}" | fzf)
  kc_app_${choice}
}
function kc_app_delete_clusters() {
  k3d cluster delete -a
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
    select_kube_ctx_cp
    multi_kube_ctx
    kube_new_window
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
function kc_app_k9s_select_kube_ctx_cp() {
  tmux send "export KUBECONFIG=\"\$(ks pipe)\"" C-Space "&& kcc" Enter
}
function kc_app_k9s_multi_kube_ctx() {
  ks tmux_multi
}
function kc_app_k9s_kube_new_window() {
  ks tmux_window
}
