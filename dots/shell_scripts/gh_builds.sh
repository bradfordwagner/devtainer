#!/bin/zsh

# gh_builds.sh — live dashboard of GitHub Actions runs that have not finished
# (queued / waiting / pending / in_progress) across your repos, with per-run
# job progress: completed/total jobs, percent, and a bar.
#
# GitHub has no "all my runs" endpoint, so we list each owner's repos, keep the
# ones pushed to recently (a run nearly always follows a push), and fetch the
# latest runs of each in parallel. Only unfinished runs cost a second call for
# their jobs. Every refresh is ~1 + repos + active-runs API calls, so keep the
# window (-d) and interval (-n) sane against the 5000/hr limit; the header
# shows what is left.
#
# Live mode keeps runs that finish while it is open: they stay on screen,
# marked with their conclusion, below the active ones. It remembers the run ids
# it saw active in a temp dir, and caches each finished run's row there so it
# costs no more API calls. -1 has no memory, so it shows only active runs.
#
# REPO links to the repo's Actions page, WORKFLOW to the run itself (OSC 8
# hyperlinks: cmd/ctrl+click in ghostty, alacritty, Windows Terminal; tmux
# passes them through via the `hyperlinks` terminal-feature in tmux.conf).
#
# Usage: gh_builds.sh [-o OWNER]... [-d DAYS] [-n SECS] [-p PARALLEL] [-1]
#   -o OWNER   user/org to scan, repeatable        (default: your gh login)
#   -d DAYS    only repos pushed within DAYS      (default: 3, 0 = all repos)
#   -n SECS    refresh interval                   (default: 15)
#   -p N       parallel repo fetches              (default: 8)
#   -1         print once and exit (no live mode)
#   -m N       concurrent job cap to track against   (default: 20, GitHub Free)
#
# Requires: gh (authenticated), jq.

# Worker mode: one repo, emit one TSV line per unfinished run, plus finished
# runs whose id is in $GH_BUILDS_STATE/seen. Status is the conclusion once
# finished, and age becomes the run's duration.
#   finished(0|1)  repo  id  workflow  branch  status  age_secs  done  running  queued  total  url
# Fields must never be empty: tab is IFS whitespace, so `read` collapses runs of it.
if [[ "$1" == "--_repo" ]]; then
  repo="$2" state="${GH_BUILDS_STATE}" seen=/dev/null
  [[ -n "${state}" ]] && seen="${state}/seen"
  gh api "repos/${repo}/actions/runs?per_page=30" 2>/dev/null \
    | jq -r --rawfile seen "${seen}" '
        ($seen | split("\n")) as $s
        | .workflow_runs[]
        | select(.status != "completed" or ((.id | tostring) as $i | any($s[]; . == $i)))
        | [.id, (.name // "-"), (.head_branch // "-"),
           (if .status == "completed" then .conclusion // "completed" else .status end),
           ((if .status == "completed" then .updated_at | fromdateiso8601 else now end)
             - (.run_started_at // .created_at | fromdateiso8601) | floor),
           .html_url] | @tsv' \
    | while IFS=$'\t' read -r id name branch run_status age url; do
        cache="${state}/done/${id}"
        if [[ -n "${state}" && -f "${cache}" ]]; then
          cat "${cache}"
          continue
        fi
        jobs=$(gh api "repos/${repo}/actions/runs/${id}/jobs?per_page=100" 2>/dev/null \
          | jq -r '[.jobs[] | .status]
                   | [(map(select(. == "completed")) | length),
                      (map(select(. == "in_progress")) | length),
                      (map(select(. == "queued" or . == "waiting" or . == "pending")) | length),
                      length] | @tsv')
        finished=1
        case "${run_status}" in queued|in_progress|waiting|pending|requested) finished=0 ;; esac
        line="${finished}"$'\t'"${repo}"$'\t'"${id}"$'\t'"${name}"$'\t'"${branch}"$'\t'"${run_status}"$'\t'"${age}"$'\t'"${jobs:-$'0\t0\t0\t0'}"$'\t'"${url}"
        print -r -- "${line}"
        (( finished )) && [[ -n "${state}" ]] && print -r -- "${line}" > "${cache}"
      done
  exit 0
fi

owners=()
days=3
interval=15
parallel=8
once=0
max_jobs=20
while getopts "o:d:n:p:m:1h" opt; do
  case "${opt}" in
    o) owners+=("${OPTARG}") ;;
    d) days="${OPTARG}" ;;
    n) interval="${OPTARG}" ;;
    p) parallel="${OPTARG}" ;;
    1) once=1 ;;
    m) max_jobs="${OPTARG}" ;;
    *) sed -n '3,31p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
  esac
done
(( ${#owners} )) || owners=("$(gh api user -q .login)") || exit 1

self="${0:A}"

c_reset=$'\e[0m' c_dim=$'\e[2m' c_bold=$'\e[1m'
c_green=$'\e[32m' c_yellow=$'\e[33m' c_blue=$'\e[34m' c_cyan=$'\e[36m'

fmt_age() {
  local s=$1
  if (( s >= 3600 )); then printf '%dh%02dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
  elif (( s >= 60 )); then printf '%dm%02ds' $(( s / 60 )) $(( s % 60 ))
  else printf '%ds' "${s}"; fi
}

# OSC 8 hyperlink: TEXT shows as-is, click opens URL. Pad TEXT before wrapping;
# the escape bytes are invisible but printf would count them toward the width.
link() { printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$1" "$2"; }

bar() {
  local pct=$1 width=${2:-20} color=${3:-${c_green}} filled
  (( pct > 100 )) && pct=100
  filled=$(( pct * width / 100 ))
  printf '%s%s%s%s' "${color}" "${(l:filled::█:)}" "${c_dim}${(l:$(( width - filled ))::░:)}" "${c_reset}"
}

list_repos() {
  local cutoff=0 owner
  (( days > 0 )) && cutoff=$(( $(date +%s) - days * 86400 ))
  for owner in "${owners[@]}"; do
    gh repo list "${owner}" --no-archived --limit 1000 --json nameWithOwner,pushedAt \
      | jq -r --argjson cutoff "${cutoff}" \
          '.[] | select((.pushedAt | fromdateiso8601) >= $cutoff) | .nameWithOwner'
  done
}

render() {
  local repos rows out rate n_repos
  repos=$(list_repos)
  n_repos=$(print -r -- "${repos}" | grep -c .)
  rows=$(print -r -- "${repos}" | grep . \
    | xargs -P "${parallel}" -I{} "${self}" --_repo {} \
    | sort -t$'\t' -k1,1n -k2,2 -k7,7nr)
  [[ -n "${GH_BUILDS_STATE}" ]] \
    && print -r -- "${rows}" | awk -F'\t' '$1 == 0 { print $3 }' >> "${GH_BUILDS_STATE}/seen"
  rate=$(gh api rate_limit -q '"\(.resources.core.remaining)/\(.resources.core.limit)"' 2>/dev/null)

  out="${c_bold}GitHub builds${c_reset}  ${c_dim}${(j:, :)owners} · ${n_repos} repos pushed $( (( days > 0 )) && print "≤${days}d" || print "any time") · api ${rate} · $(date '+%H:%M:%S')${c_reset}"$'\n\n'

  if [[ -z "${rows}" ]]; then
    out+="${c_dim}No queued or running builds.${c_reset}"$'\n'
  else
    local finished repo id name branch run_status age done_n running queued total url pct color jobs
    local n_runs=0 n_running_runs=0 n_finished=0 sum_done=0 sum_running=0 sum_queued=0 sum_total=0
    out+=$(printf "${c_bold}%-34s %-24s %-20s %-11s %7s %5s  %-20s %8s${c_reset}" \
      REPO WORKFLOW BRANCH STATUS JOBS % PROGRESS AGE)$'\n'
    while IFS=$'\t' read -r finished repo id name branch run_status age done_n running queued total url; do
      if (( finished )); then
        (( n_finished++ ))
      else
        (( n_runs++, sum_done += done_n, sum_running += running, sum_queued += queued, sum_total += total ))
        [[ "${run_status}" == in_progress ]] && (( n_running_runs++ ))
      fi
      pct=0; (( total > 0 )) && pct=$(( done_n * 100 / total ))
      case "${run_status}" in
        in_progress) color="${c_blue}" ;;
        queued)      color="${c_yellow}" ;;
        waiting|pending|requested) color="${c_cyan}" ;;
        success)     color="${c_green}" ;;
        failure|timed_out|startup_failure) color=$'\e[31m' ;;
        *)           color="${c_dim}" ;;
      esac
      jobs="${done_n}/${total}"; (( total == 0 )) && jobs="-"
      out+=$(printf "%s %s %-20.20s ${color}%-11.11s${c_reset} %7s %4d%%  %s %8s" \
        "$(link "https://github.com/${repo}/actions" "$(printf '%-34.34s' "${repo#*/}")")" \
        "$(link "${url}" "$(printf '%-24.24s' "${name}")")" "${branch}" "${run_status}" "${jobs}" "${pct}" "$(bar "${pct}")" "$(fmt_age "${age}")")
      (( running > 0 )) && out+=" ${c_dim}(${running} running)${c_reset}"
      out+=$'\n'
    done <<< "${rows}"
    pct=0; (( sum_total > 0 )) && pct=$(( sum_done * 100 / sum_total ))
    out+=$'\n'"${c_bold}${n_runs} active runs (${n_running_runs} running) · ${sum_done}/${sum_total} jobs · ${pct}%${c_reset}"
    (( n_finished )) && out+="  ${c_dim}${n_finished} finished this session${c_reset}"
    out+=$'\n'
    # GitHub caps concurrently running *jobs* per account (Free: 20), not
    # runs; anything over the cap sits queued until a slot frees up.
    pct=$(( sum_running * 100 / max_jobs ))
    color="${c_green}"; (( pct >= 75 )) && color="${c_yellow}"; (( pct >= 100 )) && color=$'\e[31m'
    out+="${c_bold}concurrency${c_reset}  ${color}${sum_running}/${max_jobs}${c_reset} jobs running $(bar "${pct}" 40 "${color}") ${pct}%  ${c_dim}${sum_queued} jobs queued${c_reset}"$'\n'
  fi
  print -rn -- "${out}"
}

if (( once )); then
  render
  exit 0
fi

# Live mode: alternate screen, build each frame fully before drawing it so the
# slow fetch never leaves a blank or half-drawn screen.
export GH_BUILDS_STATE="$(mktemp -d "${TMPDIR:-/tmp}/gh_builds.XXXXXX")"
mkdir "${GH_BUILDS_STATE}/done"; touch "${GH_BUILDS_STATE}/seen"
tput smcup; tput civis
trap 'tput cnorm; tput rmcup; rm -rf "${GH_BUILDS_STATE}"; exit 0' INT TERM EXIT
while true; do
  frame=$(render)
  tput cup 0 0; tput ed
  print -r -- "${frame}"
  print -rn -- $'\n'"${c_dim}refresh ${interval}s · ctrl+c to quit${c_reset}"
  sleep "${interval}"
done
