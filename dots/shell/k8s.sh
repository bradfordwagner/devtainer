################################################
# kubectl / kubernetes / k8s helpers
################################################
function set_pod_name() {
  export pod_name=$(k get po | fzf | awk '{ print $1 }')
}

function az_aks_get_all {
  az aks list | jq '.[] | "\(.name) \(.resourceGroup)"' -r | xargs -n2 zsh -c 'az aks get-credentials --resource-group $2 --name $1 --admin --overwrite-existing' zsh
}

function k8sUniqueContainers() {
kubectl get pods --all-namespaces -o jsonpath="{..image}" |\
tr -s '[[:space:]]' '\n' |\
sort |\
uniq -c
}

function stripRegistryLogin() {
  # sample input
  # "$ sudo docker login -p DeTg7d8Tz5-uqdHsemMXqfTPaX2avQnxX3vNS0jBkvY -e unused -u unused docker-registry-default.devkubewd.dev.blackrock.com"
  input=$1
  a=$(sed -e "s/^\$ sudo //" <<< $input)
  a=$(sed -e "s/ -e unused//" <<< $a)
  echo running: $a
  eval $a
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
alias snsk="s ns; k9"
alias kn="kubens"
alias kna="kn astra"
alias knc="kubens -c"
alias azi="az interactive"

# setup helm
alias hd='helm delete'
alias hl='helm ls'
alias hla='helm ls -a'

# set interval on k9s to 1 second
function k9() {
  k9s --headless -n $(knc) -r 1
}
alias sk="s ns; k9"
alias k9a='k9s -r 1 -A'
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
alias kwai='clear; echo kube_config=$KUBECONFIG; ll ~/.kube/config; kubectx -c; knc; hla'
################################################

## smart completions - kc ######################
################################################
export kc_tmp_dir=/tmp/kc
function kc() {
  clear
  items=(
    context
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
  local split=${1}
  original_kubeconfig=${KUBECONFIG}
  resolved_kubeconfig=${original_kubeconfig:-~/.kube/config}
  mkdir -p ${kc_tmp_dir}

  ctx_name=$(k config current-context)
  file=$(mktemp ${kc_tmp_dir}/${ctx_name}.XXXXX)
  cp -L ${resolved_kubeconfig} ${file} # follow the link
  export KUBECONFIG=${file}   # update kubeconfig to the temporary file

  # prompt for a split if not provided as an arg
  items=(
    -v
    -h
    inplace
  )
  [[ "${split}" == "" ]] && split=$(printf "%s\n" "${items[@]}" | fzf  --prompt 'tmux split: ')

  if [[ "inplace" == "${split}" ]]; then
    echo in place!
    export KUBECONFIG=${file}
    # s ns
  else
    pane_index=$(tmux splitw ${split} -P -F "#{pane_index}")
    tmux send -t ${pane_index} "export KUBECONFIG=${file}" ENTER
    tmux send -t ${pane_index} "s ns" ENTER

    # reset to original kubeconfig
    export KUBECONFIG=${original_kubeconfig}
  fi
}

