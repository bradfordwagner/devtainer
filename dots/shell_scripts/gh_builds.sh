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
# Live mode sends conditional requests (If-None-Match): GitHub answers an
# unchanged URL with a free 304, so only repos whose runs moved cost calls.
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
# Requires: gh (authenticated), jq, yq.

# Worker mode: one repo, emit one TSV line per unfinished run, plus finished
# runs whose id is in $GH_BUILDS_STATE/seen. Status is the conclusion once
# finished, and age becomes the run's duration.
#   finished(0|1)  repo  id  workflow  branch  status  age_secs  done  running  queued  total  spawned  url
# Jobs are refetched every refresh while a run is active, because a run's job
# count is not fixed: a matrix built from an earlier job's output only adds its
# jobs once that job finishes. spawned = jobs added since live mode first saw
# the run, kept in $GH_BUILDS_STATE/total.
#
# The API also lists a job only once it is created, and a job is created only
# when its `needs` are done: a `manifest` job after a matrix is invisible until
# the matrix ends. So total also counts workflow jobs (read from the run's
# workflow file at its commit) that no created job matches yet, one each, since
# a matrix's width is unknown until it starts.
# Fields must never be empty: tab is IFS whitespace, so `read` collapses runs of it.
if [[ "$1" == "--_repo" ]]; then
  # Input: workflow file as JSON. $names: names of the jobs created so far.
  # Output: how many workflow jobs have no created job yet. A job's created name
  # is its literal `name` (plus " (matrix values)"), "<name> / ..." for a
  # reusable workflow, or a pattern when `name` holds ${{ }}. Patterns only
  # match names no literal job claimed, and a job never counts as created
  # before everything it `needs` has.
  pending_jq='def esc: gsub("(?<c>[.*+?^$()\\[\\]{}|\\\\/])"; "\\\(.c)");
def templated: test("\\$\\{\\{");
def pattern($k):
  (.name // $k | tostring) as $n
  | if .uses then "^" + ($n | esc) + " / "
    elif ($n | templated) then "^" + ([$n | splits("\\$\\{\\{.*?\\}\\}")] | map(esc) | join(".*")) + "$"
    else "^" + ($n | esc) + "( \\(.*\\))?$" end;
(.jobs // {}) as $jobs
| [$jobs | to_entries[] | {k: .key, needs: ([.value.needs // empty] | flatten),
    tmpl: ((.value.name // .key | tostring) | templated), re: (.value | pattern(.key))}] as $defs
| [$defs[] | select(.tmpl | not) | .re as $re | $names[] | select(test($re))] as $claimed
| ($defs | map(.re as $re | .tmpl as $t | {key: .k, value:
      any($names[]; test($re) and (($t | not) or (. as $n | $claimed | index([$n]) | not)))})
  | from_entries) as $matched
| reduce range($defs | length) as $_ ($matched;
    . as $c | reduce $defs[] as $d (.; .[$d.k] = ($matched[$d.k] and all($d.needs[]; $c[.] // true))))
| . as $created
| [$defs[] | select($created[.k] | not)] | length'
  repo="$2" state="${GH_BUILDS_STATE}" seen=/dev/null
  [[ -n "${state}" ]] && seen="${state}/seen"
  # Tell the parent this repo is done, for its loading bar, however we exit.
  [[ -n "${GH_BUILDS_PROGRESS}" ]] && trap 'print >> "${GH_BUILDS_PROGRESS}"' EXIT

  # api URL: GET URL, conditionally in live mode. GitHub does not count a 304
  # Not Modified against the rate limit, so we keep each URL's ETag and body
  # and send If-None-Match: an idle repo then costs nothing per refresh.
  # (gh exits 1 on a 304, so read the status line rather than the exit code.)
  api() {
    local url=$1 key out code etag
    if [[ -z "${state}" ]]; then
      gh api "${url}" 2>/dev/null
      return
    fi
    key="${state}/http/${url//[^A-Za-z0-9]/_}"
    local cond=()
    [[ -s "${key}.etag" && -s "${key}.body" ]] && cond=(-H "If-None-Match: $(<"${key}.etag")")
    out=$(gh api -i "${cond[@]}" "${url}" 2>/dev/null)
    code=${${(f)out}[1][(w)2]}
    if [[ "${code}" == 304 ]]; then
      cat "${key}.body"
    elif [[ "${code}" == 200 ]]; then
      etag=$(print -r -- "${out}" | awk 'tolower($1) == "etag:" { sub(/^[^:]*: */, ""); sub(/\r$/, ""); print; exit } /^\r?$/ { exit }')
      print -r -- "${out}" | awk 'b { print; next } /^\r?$/ { b = 1 }' > "${key}.body"
      print -r -- "${etag}" > "${key}.etag"
      cat "${key}.body"
    fi
  }

  api "repos/${repo}/actions/runs?per_page=30" \
    | jq -r --rawfile seen "${seen}" '
        ($seen | split("\n")) as $s
        | .workflow_runs[]
        | select(.status != "completed" or ((.id | tostring) as $i | any($s[]; . == $i)))
        | [.id, (.name // "-"), (.head_branch // "-"),
           (if .status == "completed" then .conclusion // "completed" else .status end),
           ((if .status == "completed" then .updated_at | fromdateiso8601 else now end)
             - (.run_started_at // .created_at | fromdateiso8601) | floor),
           .html_url, (.path | sub("@.*"; "")), .head_sha] | @tsv' \
    | while IFS=$'\t' read -r id name branch run_status age url wf_path sha; do
        cache="${state}/done/${id}"
        # A re-run reuses the run id, so only trust the cache while it is still finished.
        [[ "${run_status}" == (queued|in_progress|waiting|pending|requested) ]] && rm -f "${cache}"
        if [[ -n "${state}" && -f "${cache}" ]]; then
          cat "${cache}"
          continue
        fi
        jobs_json=$(api "repos/${repo}/actions/runs/${id}/jobs?per_page=100")
        if (( $(print -r -- "${jobs_json}" | jq '.total_count // 0' 2>/dev/null) > 100 )); then
          # A big matrix passes the 100-jobs-per-page cap: fetch every page.
          job_rows=$(gh api --paginate "repos/${repo}/actions/runs/${id}/jobs?per_page=100" \
            -q '.jobs[] | [.status, .name] | @tsv' 2>/dev/null)
        else
          job_rows=$(print -r -- "${jobs_json}" | jq -r '.jobs[] | [.status, .name] | @tsv' 2>/dev/null)
        fi
        pending=0
        if [[ "${run_status}" != (success|failure|cancelled|skipped|timed_out|neutral|stale|action_required|startup_failure|completed) ]]; then
          wf_cache="${state}/wf/${sha}-${wf_path:t}.json"
          if [[ -n "${state}" && -s "${wf_cache}" ]]; then
            wf=$(<"${wf_cache}")
          else
            wf=$(gh api "repos/${repo}/contents/${wf_path}?ref=${sha}" -q .content 2>/dev/null | base64 -d 2>/dev/null | yq -o json 2>/dev/null)
            [[ -n "${state}" && -n "${wf}" ]] && print -r -- "${wf}" > "${wf_cache}"
          fi
          [[ -n "${wf}" ]] && pending=$(print -r -- "${wf}" \
            | jq --argjson names "$(print -r -- "${job_rows}" | cut -f2 | grep . | jq -R . | jq -sc .)" "${pending_jq}" 2>/dev/null)
        fi
        jobs=$(print -r -- "${job_rows}" | awk -F'\t' -v p="${pending:-0}" '
                 $1 == "completed" { d++ } $1 == "in_progress" { r++ }
                 $1 == "queued" || $1 == "waiting" || $1 == "pending" { q++ } $1 != "" { n++ }
                 END { printf "%d\t%d\t%d\t%d", d, r, q, n + p }')
        spawned=0
        if [[ -n "${state}" ]]; then
          total=${jobs##*$'\t'}
          [[ -f "${state}/total/${id}" ]] || print -r -- "${total}" > "${state}/total/${id}"
          spawned=$(( total - $(<"${state}/total/${id}") ))
        fi
        finished=1
        case "${run_status}" in queued|in_progress|waiting|pending|requested) finished=0 ;; esac
        line="${finished}"$'\t'"${repo}"$'\t'"${id}"$'\t'"${name}"$'\t'"${branch}"$'\t'"${run_status}"$'\t'"${age}"$'\t'"${jobs:-$'0\t0\t0\t0'}"$'\t'"${spawned}"$'\t'"${url}"
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
    *) sed -n '3,34p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
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

# bar DONE RUNNING TOTAL [WIDTH] [COLOR]: DONE share in COLOR (green), RUNNING
# share in yellow after it, the rest dim. Any running job gets at least one cell.
bar() {
  local done_n=$1 running=$2 total=$3 width=${4:-20} color=${5:-${c_green}} d r
  (( total > 0 )) || total=1
  d=$(( done_n * width / total ))
  (( d > width )) && d=${width}
  r=$(( (done_n + running) * width / total - d ))
  (( running > 0 && r == 0 )) && r=1
  (( d + r > width )) && r=$(( width - d ))
  printf '%s%s%s%s%s%s' "${color}" "${(l:d::█:)}" "${c_yellow}" "${(l:r::█:)}" \
    "${c_dim}${(l:$(( width - d - r ))::░:)}" "${c_reset}"
}

spinner=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

# drain LEFT TOTAL WIDTH [BUBBLE]: bar of LEFT/TOTAL, with a partial block
# (▏…▉) at its edge. BUBBLE, if given, sits in the first empty cell.
drain() {
  local eighths=$(( $1 * $3 * 8 / $2 )) partials=(▏ ▎ ▍ ▌ ▋ ▊ ▉) full part
  (( eighths > $3 * 8 )) && eighths=$(( $3 * 8 ))
  full=$(( eighths / 8 )) part=$(( eighths % 8 ))
  local edge="" empty bubble=""
  (( part > 0 )) && edge=${partials[part]}
  empty=$(( $3 - full - (part > 0) ))
  [[ -n "$4" ]] && (( empty > 0 )) && bubble=$4 && (( empty-- ))
  printf '%s%s%s%s%s%s' "${c_cyan}" "${(l:full::█:)}" "${edge}" "${bubble}" \
    "${c_dim}${(l:empty::·:)}" "${c_reset}"
}

# Bubbles rising off the refresh bar's edge while it fills: blub blub blub.
bubbles=(˳ ∘ ° o O ° ∘)

list_repos() {
  local cutoff=0 owner
  (( days > 0 )) && cutoff=$(( $(date +%s) - days * 86400 ))
  for owner in "${owners[@]}"; do
    gh repo list "${owner}" --no-archived --limit 1000 --json nameWithOwner,pushedAt \
      | jq -r --argjson cutoff "${cutoff}" \
          '.[] | select((.pushedAt | fromdateiso8601) >= $cutoff) | .nameWithOwner'
  done
}

# loading DONE TOTAL: progress line on the terminal (not stdout, which render's
# caller captures) while the first fetch runs. TOTAL 0 = still listing repos.
loading() {
  if (( $2 == 0 )); then
    printf '\r\e[K%sLoading builds%s  %slisting repos…%s' "${c_bold}" "${c_reset}" "${c_dim}" "${c_reset}"
  else
    printf '\r\e[K%sLoading builds%s  %s %d/%d repos' "${c_bold}" "${c_reset}" "$(bar "$1" 0 "$2" 30)" "$1" "$2"
  fi
} > /dev/tty

# render: fetch everything, print one frame. With $show_loading set, draw a
# loading bar meanwhile; otherwise refill the footer bar in live mode.
render() {
  local repos rows out rate n_repos tmp pid
  if (( show_loading )); then
    loading 0 0
  elif (( ! once )); then
    printf '\r\e[K%s%s%s %s%-14s%s %s %slisting repos…%s' "${c_cyan}" "${spinner[1]}" "${c_reset}" \
      "${c_dim}" "refreshing" "${c_reset}" "$(drain 0 1 20 "${bubbles[1]}")" "${c_dim}" "${c_reset}" > /dev/tty
  fi
  repos=$(list_repos)
  n_repos=$(print -r -- "${repos}" | grep -c .)
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/gh_builds_render.XXXXXX")
  touch "${tmp}/progress"
  print -r -- "${repos}" | grep . \
    | GH_BUILDS_PROGRESS="${tmp}/progress" xargs -P "${parallel}" -I{} "${self}" --_repo {} > "${tmp}/rows" &
  pid=$!
  # The refresh bar refills what the countdown drained. Repos finish in jumps,
  # so the bar eases halfway to the real fill each tick instead of snapping.
  local tick=0 shown=0 target done_n
  while kill -0 "${pid}" 2>/dev/null; do
    done_n=$(wc -l < "${tmp}/progress")
    if (( show_loading )); then
      loading "${done_n}" "${n_repos}"
    elif (( ! once )); then
      target=$(( n_repos > 0 ? done_n * 160 / n_repos : 0 ))
      (( shown < target )) && shown=$(( shown + (target - shown + 1) / 2 ))
      printf '\r\e[K%s%s%s %s%-14s%s %s %s%d/%d repos%s' "${c_cyan}" "${spinner[tick % ${#spinner} + 1]}" "${c_reset}" \
        "${c_dim}" "refreshing" "${c_reset}" "$(drain "${shown}" 160 20 "${bubbles[tick % ${#bubbles} + 1]}")" \
        "${c_dim}" "${done_n}" "${n_repos}" "${c_reset}" > /dev/tty
    fi
    (( tick++ ))
    sleep 0.1
  done
  wait "${pid}"
  (( show_loading )) && printf '\r\e[K' > /dev/tty
  rows=$(sort -t$'\t' -k1,1n -k2,2 -k7,7nr < "${tmp}/rows")
  rm -rf "${tmp}"
  [[ -n "${GH_BUILDS_STATE}" ]] \
    && print -r -- "${rows}" | awk -F'\t' '$1 == 0 { print $3 }' >> "${GH_BUILDS_STATE}/seen"
  rate=$(gh api rate_limit -q '"\(.resources.core.remaining)/\(.resources.core.limit)"' 2>/dev/null)

  out="${c_bold}GitHub builds${c_reset}  ${c_dim}${(j:, :)owners} · ${n_repos} repos pushed $( (( days > 0 )) && print "≤${days}d" || print "any time") · api ${rate} · $(date '+%H:%M:%S')${c_reset}"$'\n\n'

  if [[ -z "${rows}" ]]; then
    out+="${c_dim}No queued or running builds.${c_reset}"$'\n'
  else
    local finished repo id name branch run_status age done_n running queued total spawned url pct color jobs
    local n_runs=0 n_running_runs=0 n_queued_runs=0 n_finished=0 sum_done=0 sum_running=0 sum_queued=0 sum_total=0
    out+=$(printf "${c_bold}%-34s %-24s %-20s %-11s %7s %5s  %-20s %8s${c_reset}" \
      REPO WORKFLOW BRANCH STATUS JOBS % PROGRESS AGE)$'\n'
    while IFS=$'\t' read -r finished repo id name branch run_status age done_n running queued total spawned url; do
      if (( finished )); then
        (( n_finished++ ))
      else
        (( n_runs++, sum_done += done_n, sum_running += running, sum_queued += queued, sum_total += total ))
        # Go by jobs, not the run's status: GitHub flips a run to in_progress late
        # (or early, while its jobs still wait for a runner). Running jobs = in progress.
        if (( running > 0 )); then
          run_status=in_progress
          (( n_running_runs++ ))
        else
          [[ "${run_status}" == in_progress ]] && run_status=queued
          (( n_queued_runs++ ))
        fi
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
        "$(link "${url}" "$(printf '%-24.24s' "${name}")")" "${branch}" "${run_status}" "${jobs}" "${pct}" "$(bar "${done_n}" "${running}" "${total}")" "$(fmt_age "${age}")")
      (( running > 0 )) && out+=" ${c_yellow}${running} in progress${c_reset}"
      (( spawned > 0 )) && out+=" ${c_cyan}+${spawned} spawned${c_reset}"
      out+=$'\n'
    done <<< "${rows}"
    pct=0; (( sum_total > 0 )) && pct=$(( sum_done * 100 / sum_total ))
    out+=$'\n'"${c_bold}${c_blue}${n_running_runs} runs in progress${c_reset}${c_bold} · ${c_yellow}${n_queued_runs} queued${c_reset}${c_bold} · ${sum_done}/${sum_total} jobs done, ${c_yellow}${sum_running} in progress${c_reset}${c_bold} · ${pct}%${c_reset}"
    (( n_finished )) && out+="  ${c_dim}${n_finished} finished this session${c_reset}"
    out+=$'\n'
    # GitHub caps concurrently running *jobs* per account (Free: 20), not
    # runs; anything over the cap sits queued until a slot frees up.
    pct=$(( sum_running * 100 / max_jobs ))
    color="${c_green}"; (( pct >= 75 )) && color="${c_yellow}"; (( pct >= 100 )) && color=$'\e[31m'
    out+="${c_bold}concurrency${c_reset}  ${color}${sum_running}/${max_jobs}${c_reset} jobs running $(bar "${sum_running}" 0 "${max_jobs}" 40 "${color}") ${pct}%  ${c_dim}${sum_queued} jobs queued${c_reset}"$'\n'
  fi
  print -rn -- "${out}"
}

show_loading=0
if (( once )); then
  [[ -t 1 ]] && show_loading=1
  render
  exit 0
fi

# Live mode: alternate screen, build each frame fully before drawing it so the
# slow fetch never leaves a blank or half-drawn screen.
export GH_BUILDS_STATE="$(mktemp -d "${TMPDIR:-/tmp}/gh_builds.XXXXXX")"
mkdir "${GH_BUILDS_STATE}/done" "${GH_BUILDS_STATE}/total" "${GH_BUILDS_STATE}/wf" "${GH_BUILDS_STATE}/http"; touch "${GH_BUILDS_STATE}/seen"
tput smcup; tput civis; tput cup 0 0
show_loading=1
trap 'tput cnorm; tput rmcup; rm -rf "${GH_BUILDS_STATE}"; exit 0' INT TERM HUP EXIT
while true; do
  frame=$(render)
  show_loading=0
  tput cup 0 0; tput ed
  print -r -- "${frame}"
  print
  # Countdown at 10 ticks/s: braille spinner plus a bar that drains in
  # eighth-cell steps, so it moves smoothly even at long intervals.
  ticks=$(( interval * 10 ))
  for (( t = ticks; t > 0; t-- )); do
    printf '\r\e[K%s%s%s %s%-14s%s %s %s· ctrl+c to quit%s' "${c_cyan}" "${spinner[(ticks - t) % ${#spinner} + 1]}" "${c_reset}" \
      "${c_dim}" "refresh in $(( (t + 9) / 10 ))s" "${c_reset}" "$(drain "${t}" "${ticks}" 20)" "${c_dim}" "${c_reset}"
    sleep 0.1
  done
done
