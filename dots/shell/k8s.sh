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
alias kc=kubectx
alias kcc="kubectx -c"
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
function kcp() {
  # file=$(mktemp /tmp/kubecontext.XXXX)
  # echo file=${file}
  # ll ${file}

  KUBECONFIG=~/.kube/config

  ctx_name=$(k config current-context)
  # file=$(mktemp /tmp/${ctx_name}.XXXXX)
  file=$(mktemp /tmp/${ctx_name}.XXXXX)
  cp -L ${KUBECONFIG} ${file} # follow the link
  export KUBECONFIG=${file}

  # s ns

  # check ks for tmuxSendToPane


  # cp -L ~/.kube/config ${file}
  # ll ${file}
  # bat -P -lyaml ${file}
  # ls -lh ${file}
  # rm ${file}
  # ll ${file}
}
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
alias kwai='clear; echo kube_config=$KUBECONFIG; ll ~/.kube/config; kcc; knc; hla'
################################################
