#!/usr/bin/env bash
# Resolve the UI URL for a thing a deployment step touches.
#
#   deploy-links.sh bases                     # every base URL that resolves right now
#   deploy-links.sh argocd <app> [<ns>]       # ArgoCD application
#   deploy-links.sh kargo <project> [<stage>] # Kargo project, or one stage in it
#   deploy-links.sh workflow <ns> <name>      # Argo Workflows run
#   deploy-links.sh gh-pr <number|url>        # pull request
#   deploy-links.sh gh-run <id>               # Actions run
#   deploy-links.sh gh-run-for <sha>          # the run a push just triggered
#   deploy-links.sh gh-actions                # this repo's Actions tab
#   deploy-links.sh promotion <proj> <id>     # a Kargo promotion just created
#   deploy-links.sh vault <mount> <path>      # Vault KV secret
#
# Written for bw-deployment-releaser, which prints the links for a wave before it
# runs anything so the human can watch the release happen rather than read about
# it afterwards. The whole point is that they are openable, which makes a wrong
# one worse than none: a plausible-looking URL to a cluster you are not pointed
# at is indistinguishable from a working one until it 404s, and by then the step
# has run. So every URL here is built from something the machine already knows --
# `argocd context`, `kargo config view`, `gh`, $VAULT_ADDR -- and a base that does
# not resolve is an error with a reason, never a guess.
#
# Some links cannot exist before the step runs: a `git push` triggers a run whose
# id GitHub assigns, `argo submit` names a workflow with a generated suffix, a
# promotion gets an id on creation. Those are the links the user most wants --
# something is running right now -- and they are worth a second call the instant
# the identifier appears rather than a wait until the wave reports. Hence
# `gh-run-for <sha>`, which finds the run a commit triggered, and `promotion`;
# and hence the note in the releaser's prompt to capture the name `argo submit -o
# name` prints instead of resolving it by guesswork afterwards.
#
# `gh-run-for` polls, briefly. A run does not appear the instant a push lands, so
# resolving once and giving up would fail exactly when it is called -- right after
# the push. It retries for ~30s (override DEPLOY_LINKS_WAIT) and exits 1 saying so
# if nothing appeared, which is a real answer: no run for that sha usually means
# no workflow matched the branch or path filter, and that is worth knowing early.
#
# One URL per invocation on stdout, diagnostics on stderr, so it composes.
#
# Overrides, for when the CLI points somewhere the browser cannot follow (an
# in-cluster service address, say) -- set these in the environment:
#   DEPLOY_LINKS_ARGOCD_URL  DEPLOY_LINKS_KARGO_URL
#   DEPLOY_LINKS_ARGO_URL    DEPLOY_LINKS_VAULT_URL
#
# Exit 0 a URL was printed, 1 the base could not be resolved (nothing printed),
# 2 the tool could not run -- the same convention as its siblings.

set -uo pipefail

usage() { sed -n '2,46p' "$0" | sed 's/^# \?//'; }

[[ $# -eq 0 || ${1:-} == -h || ${1:-} == --help ]] && { usage; exit 0; }

note() { echo "deploy-links: $*" >&2; }

# https://host -- trailing slash stripped, scheme added if the source omitted it
normalize() {
  local u=${1%/}
  [[ -z $u ]] && return 1
  [[ $u == http://* || $u == https://* ]] || u="https://$u"
  # :443 is the default for https and only makes the URL uglier
  echo "${u%:443}"
}

argocd_base() {
  if [[ -n ${DEPLOY_LINKS_ARGOCD_URL:-} ]]; then normalize "$DEPLOY_LINKS_ARGOCD_URL"; return; fi
  command -v argocd >/dev/null 2>&1 || { note "argocd is not installed"; return 1; }
  local srv
  # `argocd context` marks the current one with * -- SERVER, falling back to NAME
  srv=$(argocd context 2>/dev/null | awk '$1=="*"{print ($3!="" ? $3 : $2); exit}')
  [[ -n $srv ]] || { note "no current argocd context (run: argocd login ...), and \
DEPLOY_LINKS_ARGOCD_URL is unset"; return 1; }
  normalize "$srv"
}

kargo_base() {
  if [[ -n ${DEPLOY_LINKS_KARGO_URL:-} ]]; then normalize "$DEPLOY_LINKS_KARGO_URL"; return; fi
  command -v kargo >/dev/null 2>&1 || { note "kargo is not installed"; return 1; }
  local addr
  addr=$(kargo config view 2>/dev/null | sed -n 's/^apiAddress:[[:space:]]*//p' | head -1)
  addr=${addr%\"}; addr=${addr#\"}; addr=${addr%\'}; addr=${addr#\'}
  [[ -n $addr ]] || { note "kargo has no apiAddress (run: kargo login ...), and \
DEPLOY_LINKS_KARGO_URL is unset"; return 1; }
  normalize "$addr"
}

# Argo Workflows has no config file to read -- the CLI takes its server from the
# environment, so that is the only honest source.
argo_base() {
  if [[ -n ${DEPLOY_LINKS_ARGO_URL:-} ]]; then normalize "$DEPLOY_LINKS_ARGO_URL"; return; fi
  local srv=${ARGO_SERVER:-}
  [[ -n $srv ]] || { note "\$ARGO_SERVER is unset (argo workflows is usually reached \
by port-forward here), and DEPLOY_LINKS_ARGO_URL is unset"; return 1; }
  local base
  base=$(normalize "$srv") || return 1
  [[ ${ARGO_SECURE:-} == false ]] && base=${base/https:/http:}
  echo "${base}${ARGO_BASE_HREF:+${ARGO_BASE_HREF%/}}"
}

vault_base() {
  if [[ -n ${DEPLOY_LINKS_VAULT_URL:-} ]]; then normalize "$DEPLOY_LINKS_VAULT_URL"; return; fi
  [[ -n ${VAULT_ADDR:-} ]] || { note "\$VAULT_ADDR is unset, and DEPLOY_LINKS_VAULT_URL \
is unset"; return 1; }
  normalize "$VAULT_ADDR"
}

need() {
  [[ -n ${2:-} ]] && return 0
  note "$1 needs $3"; exit 2
}

cmd=$1; shift

case $cmd in
  bases)
    # Report every base, resolved or not, so a caller can see up front which
    # links are going to be available for this wave.
    rc=1
    for kind in argocd kargo argo vault; do
      if u=$("${kind}_base" 2>/dev/null); then printf '%-8s %s\n' "$kind" "$u"; rc=0
      else printf '%-8s %s\n' "$kind" "(unresolved)"; fi
    done
    if command -v gh >/dev/null 2>&1 && u=$(gh repo view --json url -q .url 2>/dev/null) && [[ -n $u ]]; then
      printf '%-8s %s\n' github "$u"; rc=0
    else
      printf '%-8s %s\n' github "(unresolved)"
    fi
    exit $rc
    ;;

  argocd)
    need argocd "${1:-}" "an application name"
    base=$(argocd_base) || exit 1
    # an app in a non-default control-plane namespace is /applications/<ns>/<app>
    if [[ -n ${2:-} ]]; then echo "${base}/applications/$2/$1"; else echo "${base}/applications/$1"; fi
    ;;

  kargo)
    need kargo "${1:-}" "a project name"
    base=$(kargo_base) || exit 1
    if [[ -n ${2:-} ]]; then echo "${base}/project/$1/stage/$2"; else echo "${base}/project/$1"; fi
    ;;

  workflow)
    need workflow "${1:-}" "a namespace and a workflow name"
    need workflow "${2:-}" "a namespace and a workflow name"
    base=$(argo_base) || exit 1
    echo "${base}/workflows/$1/$2"
    ;;

  gh-pr)
    need gh-pr "${1:-}" "a PR number or URL"
    command -v gh >/dev/null 2>&1 || { note "gh is not installed"; exit 2; }
    u=$(gh pr view "$1" --json url -q .url 2>/dev/null) \
      || { note "gh could not read PR $1 (wrong repo, or it does not exist yet)"; exit 1; }
    echo "$u"
    ;;

  gh-run)
    need gh-run "${1:-}" "a run id"
    command -v gh >/dev/null 2>&1 || { note "gh is not installed"; exit 2; }
    u=$(gh run view "$1" --json url -q .url 2>/dev/null) \
      || { note "gh could not read run $1 (it may not have started yet)"; exit 1; }
    echo "$u"
    ;;

  gh-actions)
    command -v gh >/dev/null 2>&1 || { note "gh is not installed"; exit 2; }
    u=$(gh repo view --json url -q .url 2>/dev/null) \
      || { note "not in a github repo, or gh is not authenticated"; exit 1; }
    echo "${u}/actions"
    ;;

  gh-run-for)
    need gh-run-for "${1:-}" "a commit sha"
    command -v gh >/dev/null 2>&1 || { note "gh is not installed"; exit 2; }
    sha=$1
    # A full sha is what `git rev-parse HEAD` gives and what gh reports; accept a
    # short one by prefix-matching rather than making the caller expand it.
    deadline=$(( SECONDS + ${DEPLOY_LINKS_WAIT:-30} ))
    while :; do
      u=$(gh run list --limit 40 --json headSha,url \
            --jq "[.[] | select(.headSha | startswith(\"$sha\"))] | first | .url" 2>/dev/null)
      [[ -n $u && $u != null ]] && { echo "$u"; exit 0; }
      (( SECONDS >= deadline )) && break
      sleep 3
    done
    note "no Actions run for $sha after ${DEPLOY_LINKS_WAIT:-30}s -- either none was \
triggered (branch or path filter did not match) or it has not registered yet; \
the Actions tab is $(gh repo view --json url -q .url 2>/dev/null)/actions"
    exit 1
    ;;

  promotion)
    need promotion "${1:-}" "a project and a promotion id"
    need promotion "${2:-}" "a project and a promotion id"
    base=$(kargo_base) || exit 1
    echo "${base}/project/$1/promotion/$2"
    ;;

  vault)
    need vault "${1:-}" "a mount and a path"
    need vault "${2:-}" "a mount and a path"
    base=$(vault_base) || exit 1
    echo "${base}/ui/vault/secrets/$1/show/${2#/}"
    ;;

  *)
    note "unknown subcommand \"$cmd\""
    usage >&2
    exit 2
    ;;
esac
