################################################
# sessions - a named branch across N repos: a worktree each under
# ~/sessions/${name}, plus a tmux window. Verbs: new | add | delete, or fzf.
################################################
export SESSIONS_ROOT=${SESSIONS_ROOT:-${HOME}/sessions}
export SESSIONS_TMUX=${SESSIONS_TMUX:-sessions}
export SESSIONS_TEMPLATE=${SESSIONS_TEMPLATE:-${HOME}/.dotfiles/sessions.md}
# .git at this depth => repos at depth-1 below $PWD
export SESSIONS_SCAN_DEPTH=${SESSIONS_SCAN_DEPTH:-4}

function sessions() {
  local verb=$1
  if [[ -z "${verb}" ]]; then
    verb=$(printf 'new\nadd\ndelete\n' | fzf --reverse --height 20% --prompt='sessions: ') || return
  fi

  case "${verb}" in
    new)    _sessions_new ;;
    add)    _sessions_add ;;
    delete) _sessions_delete ;;
    *)      echo "unknown verb: ${verb} (new|add|delete)" >&2; return 1 ;;
  esac
}

################################################
# helpers
################################################

# list git repos under $PWD, parents only - a repo's own submodules/worktrees
# are not separate sessions candidates
function _sessions_find_repos() {
  find -L . -maxdepth ${SESSIONS_SCAN_DEPTH} -name .git 2>/dev/null \
    | sed -e 's|/\.git$||' -e 's|^\./||' \
    | sort \
    | awk '{ if (kept == "" || index($0, kept "/") != 1) { kept = $0; print } }'
}

function _sessions_pick_repos() {
  local repos
  repos=$(_sessions_find_repos)
  if [[ -z "${repos}" ]]; then
    echo "no git repos found under $(pwd)" >&2
    return 1
  fi
  echo "${repos}" | fzf -m --reverse --prompt='repos (tab to multi-select): '
}

function _sessions_pick_session() {
  local names
  names=$(ls -1 "${SESSIONS_ROOT}" 2>/dev/null)
  if [[ -z "${names}" ]]; then
    echo "no sessions in ${SESSIONS_ROOT}" >&2
    return 1
  fi
  echo "${names}" | fzf --reverse --prompt='session: '
}

function _sessions_default_branch() {
  local repo=$1 origin_head
  origin_head=$(git -C "${repo}" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  if [[ -n "${origin_head}" ]]; then
    echo "${origin_head#origin/}"
  elif git -C "${repo}" show-ref --verify --quiet refs/remotes/origin/main; then
    echo main
  elif git -C "${repo}" show-ref --verify --quiet refs/remotes/origin/master; then
    echo master
  fi
}

# the main checkout backing a worktree - `git worktree remove` must run there
function _sessions_main_repo() {
  local worktree=$1 common
  common=$(git -C "${worktree}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  dirname "${common}"
}

# origin url -> "<owner> <repo>", falling back to the local dir and its parent.
# scp-style remotes get the colon flattened to a slash so both forms split alike
function _sessions_remote_name() {
  local repo=$1 url
  url=$(git -C "${repo}" remote get-url origin 2>/dev/null)
  if [[ -z "${url}" ]]; then
    echo "$(basename "$(dirname "${repo}")") $(basename "${repo}")"
    return
  fi
  url=${url%.git}
  url=${url%/}
  url=${url//:/\/}
  local owner=${url%/*}
  echo "${owner##*/} ${url##*/}"
}

# worktree dir name: the repo as origin names it, or <owner>-<repo> on a clash.
# identity is checked first, or `add` hands a repo already here a second slot
function _sessions_dest() {
  local repo=$1 session=$2 owner name dir existing dest n
  read -r owner name <<< "$(_sessions_remote_name "${repo}")"
  dir="${SESSIONS_ROOT}/${session}"

  for existing in "${dir}"/*(N/); do
    if [[ "$(_sessions_main_repo "${existing}" 2>/dev/null)" == "${repo}" ]]; then
      echo "${existing%/}"
      return
    fi
  done

  dest="${dir}/${name}"
  [[ -e "${dest}" ]] && dest="${dir}/${owner}-${name}"
  n=2
  while [[ -e "${dest}" ]]; do
    dest="${dir}/${owner}-${name}-${n}"
    (( n++ ))
  done
  echo "${dest}"
}

# add ${repo} to ${session} as a worktree on branch ${session}
function _sessions_add_worktree() {
  local repo=$1 session=$2 dest err
  dest=$(_sessions_dest "${repo}" "${session}")

  if [[ -e "${dest}" ]]; then
    echo "${palette_lyellow}skip ${dest} - already exists${palette_restore}"
    return 0
  fi

  # the base comes from origin, so a failed fetch would silently branch off a
  # stale commit. no origin is the one legitimate exception - HEAD is the base.
  if git -C "${repo}" remote get-url origin >/dev/null 2>&1; then
    if ! err=$(git -C "${repo}" fetch origin --quiet 2>&1); then
      echo "${palette_lred}fetch failed in ${repo}${palette_restore}" >&2
      echo "${palette_lred}refusing to branch ${session} from a stale origin${palette_restore}" >&2
      [[ -n "${err}" ]] && print -r -- "${err}" | sed 's|^|  |' >&2
      return 1
    fi
  fi

  if git -C "${repo}" show-ref --verify --quiet "refs/heads/${session}"; then
    git -C "${repo}" worktree add "${dest}" "${session}" || return 1
  else
    local base
    base=$(_sessions_default_branch "${repo}")
    [[ -n "${base}" ]] && base="origin/${base}" || base=HEAD
    # --no-track: the branch is new work, not a second checkout of the base
    git -C "${repo}" worktree add --no-track -b "${session}" "${dest}" "${base}" || return 1
  fi
  echo "${palette_lgreen}added ${dest}${palette_restore}"
}

function _sessions_tmux_window() {
  local session=$1 dir="${SESSIONS_ROOT}/$1"
  hash tmux 2>/dev/null || return 0

  if ! tmux has-session -t "=${SESSIONS_TMUX}" 2>/dev/null; then
    tmux new-session -ds "${SESSIONS_TMUX}" -n "${session}" -c "${dir}"
  elif ! tmux list-windows -t "=${SESSIONS_TMUX}" -F '#W' | grep -qx "${session}"; then
    tmux new-window -t "=${SESSIONS_TMUX}:" -n "${session}" -c "${dir}"
  fi

  [[ -n "${TMUX}" ]] && tmux switch-client -t "=${SESSIONS_TMUX}:${session}" 2>/dev/null
}

# uncommitted changes, or commits not yet on a remote
function _sessions_worktree_dirty() {
  local worktree=$1
  [[ -n "$(git -C "${worktree}" status --porcelain 2>/dev/null)" ]] && return 0
  [[ -n "$(git -C "${worktree}" log --oneline HEAD --not --remotes 2>/dev/null)" ]] && return 0
  return 1
}

# one .beads db at the session root, reachable from any worktree. --skip-agents
# keeps our CLAUDE.md; bd's git init of the root is undone (beads.role: GH#2950)
function _sessions_beads_init() {
  local session=$1 dir="${SESSIONS_ROOT}/$1"
  hash bd 2>/dev/null || return 0
  ( cd "${dir}" && bd init --non-interactive --init-if-missing --skip-agents \
      --skip-hooks --role maintainer --prefix "${session}" -q ) || return 0
  [[ -d "${dir}/.beads" ]] && rm -rf "${dir}/.git" "${dir}/.gitignore"
  return 0
}

# open beads in the session's tracker - empty when bd or the tracker is absent.
# cd rather than `bd -C`, which does not pick up the repo's beads.role (GH#2950)
function _sessions_beads_open() {
  local dir=$1
  hash bd 2>/dev/null || return 0
  [[ -d "${dir}/.beads" ]] || return 0
  # bd interleaves throttled tips with its output, so keep only the count itself
  ( cd "${dir}" && bd count --status open 2>/dev/null ) | grep -oE '^[0-9]+$' | head -n1
}

################################################
# verbs
################################################

function _sessions_new() {
  local session repos repo failed
  read -r "session?session name: "
  session=$(echo "${session}" | tr -s ' ' '-')
  if [[ -z "${session}" ]]; then
    echo "session name required" >&2
    return 1
  fi
  if [[ -d "${SESSIONS_ROOT}/${session}" ]]; then
    echo "session ${session} already exists - use 'add'" >&2
    return 1
  fi

  repos=$(_sessions_pick_repos) || return 1
  [[ -z "${repos}" ]] && return 1

  mkdir -p "${SESSIONS_ROOT}/${session}"
  # symlink, not copy: a copy freezes at creation time, so a rules fix would
  # only reach later sessions. -n so a re-run replaces instead of nesting.
  [[ -f "${SESSIONS_TEMPLATE}" ]] && ln -sfn "${SESSIONS_TEMPLATE}" "${SESSIONS_ROOT}/${session}/CLAUDE.md"

  failed=0
  for repo in ${(f)repos}; do
    _sessions_add_worktree "$(cd "${repo}" && pwd -P)" "${session}" || failed=1
  done
  if (( failed )); then
    echo "${palette_lred}${session} is incomplete - fix the above, then 'sessions add'${palette_restore}" >&2
    return 1
  fi

  _sessions_beads_init "${session}"
  _sessions_tmux_window "${session}"
}

function _sessions_add() {
  local session repos repo failed
  session=$(_sessions_pick_session) || return 1
  [[ -z "${session}" ]] && return 1

  repos=$(_sessions_pick_repos) || return 1
  [[ -z "${repos}" ]] && return 1

  failed=0
  for repo in ${(f)repos}; do
    _sessions_add_worktree "$(cd "${repo}" && pwd -P)" "${session}" || failed=1
  done
  if (( failed )); then
    echo "${palette_lred}${session} is incomplete - fix the above and retry${palette_restore}" >&2
    return 1
  fi

  _sessions_beads_init "${session}"
}

function _sessions_delete() {
  local session dir worktrees dirty open confirm main wt
  session=$(_sessions_pick_session) || return 1
  [[ -z "${session}" ]] && return 1
  dir="${SESSIONS_ROOT}/${session}"
  if [[ ! -d "${dir}" ]]; then
    echo "no such session: ${dir}" >&2
    return 1
  fi

  # -mindepth 2: worktrees sit one level down, and a .git at the session root is
  # not a worktree of anything, so keep the root out of scope regardless
  worktrees=$(find "${dir}" -mindepth 2 -maxdepth 2 -name .git 2>/dev/null | sed 's|/\.git$||')

  dirty=()
  for wt in ${(f)worktrees}; do
    _sessions_worktree_dirty "${wt}" && dirty+=("${wt}")
  done

  open=$(_sessions_beads_open "${dir}")

  if [[ ${#dirty[@]} -gt 0 || ( -n "${open}" && "${open}" != 0 ) ]]; then
    if [[ ${#dirty[@]} -gt 0 ]]; then
      echo "${palette_lred}unsaved work in:${palette_restore}"
      printf '  %s\n' "${dirty[@]}"
    fi
    if [[ -n "${open}" && "${open}" != 0 ]]; then
      echo "${palette_lred}${open} open bead(s) - the tracker dies with the session:${palette_restore}"
      ( cd "${dir}" && bd list --status open --flat 2>/dev/null ) \
        | grep -vE '^[[:space:]]*(💡|$)' | sed 's|^|  |'
    fi
    # bd, piped through grep/sed above, leaves this shell not yet reclaimed as
    # the tty's foreground process group - a read right after it returns empty
    # instead of waiting. Any external command resyncs that before we read.
    stty -g < /dev/tty > /dev/null
    read -r confirm"?delete ${session} anyway? [y/N] " < /dev/tty
    [[ "${confirm}" == [yY]* ]] || return 1
  fi

  # branches are left alone on purpose - the only copy of unpushed work
  for wt in ${(f)worktrees}; do
    main=$(_sessions_main_repo "${wt}") && git -C "${main}" worktree remove --force "${wt}"
  done

  rm -rf "${dir}"
  tmux kill-window -t "=${SESSIONS_TMUX}:${session}" 2>/dev/null
  echo "${palette_lgreen}deleted ${session}${palette_restore}"
}
