# sessions (multi-repo worktrees)

`dots/shell/sessions.sh` defines the `sessions` function: `sessions` fzf-picks the verb,
`sessions new|add|adopt|reinit|delete` skips straight to it (`adopt` and `reinit` also take
an optional branch / session name argument).

`sessions new --empty` skips the repo pick and creates only the session root (setup + tmux
window); `add` fills it later. A flag rather than treating an empty pick as "no repos", so Esc
in the picker still cancels `new` instead of leaving a stray session behind.

A *session* is one branch name spanning N repos. `new` prompts for a name, fzf-multi-selects
git repos found under `$PWD` (recursive to `SESSIONS_SCAN_DEPTH`, parents only — a repo's own
submodules/nested worktrees are not separate candidates), and adds a `git worktree` of each on
a branch named after the session, under `~/sessions/${name}/${repo}`. `sessions.md` (repo root)
is copied in as the session's `CLAUDE.md`, then a tmux window named after the session opens in
the `sessions` tmux session (created if absent), cwd `~/sessions/${name}`.

`${repo}` is the name **origin** knows the repo by, not the local directory name — a checkout
in `work/fe-clone` whose origin is `.../frontend.git` lands at `~/sessions/${name}/frontend`;
scp-style and URL remotes both parse, and with no origin it falls back to the local dir name.
Two repos resolving to the same name get an `<owner>-<repo>` fallback (then `-2`, `-3`). But
the destination is resolved by **repo identity first**: `_sessions_dest` scans the session for
a worktree whose `--git-common-dir` is this repo and reuses that dir whatever name it got.
Without that, `add` hands a repo already in the session a second slot as soon as the plain name
is free again.

Branches are cut `--no-track` from a freshly fetched `origin/HEAD` (falling back to
`origin/main`, `origin/master`, then local `HEAD`) — the session branch is new work, so it must
not inherit the base as its upstream. That fetch is **load-bearing and checked**: `new`, `add`
and `adopt` all run `_sessions_fetch` (`fetch --all --prune`, every picked repo) before
anything reads a remote-tracking ref, and a failure stops the verb rather than branching from
whatever was last fetched. A repo with no remote is the one exemption — nothing to fetch, and
`HEAD` is the base. `--prune` is not cosmetic: a stale `origin/renovate` makes the fetch of a
new `origin/renovate/*` fail outright (see below). The verbs iterate `${(f)repos}` rather than
piping into `while`, or failure flags would die in the subshell.

## Branch names and ref conflicts

Git stores refs as files, so `renovate` and `renovate/vault` cannot coexist — one would have to
be both a file and a directory. Tools own namespaces like that (Renovate's `renovate/*`,
Dependabot's `dependabot/*`), so a session named after one blocks the tool's branches.

- **`SESSIONS_BRANCH_PREFIX`** (default empty) namespaces the branches `new` cuts: `bw` turns
  session `renovate` into branch `bw/renovate`. A trailing `/` is optional. `adopt` ignores it —
  an adopted branch keeps its own name.
- **`add` reuses the session's branch**, read from its first worktree, falling back to what
  `new` would cut. The dir name alone is not enough: `adopt` flattens `feat/x` to `feat-x`, and a
  prefix is not in the dir name.
- **Preflight**: after the fetch and before any dir is created, `_sessions_preflight` checks
  every target repo for a local or remote-tracking ref that is a path prefix or extension of the
  branch, and names it (plus the worktree holding it, if any). Remote-tracking refs count
  because pushing the branch would hit the same conflict on the remote. Without the preflight,
  the conflict fails mid-loop and leaves a half-built session dir behind.

Nothing about this touches the *original* checkout: `git worktree add` leaves its HEAD, branch
and working tree alone, so it stays readable for diffs while a session is live. The only thing
that moves there is `origin/*`, which the fetch advances. Git will refuse to check the session
branch out in the original while a worktree holds it — `log`/`diff`/`show` are unaffected. `delete` unregisters the worktrees from their *original*
checkouts (resolved via `--git-common-dir`, since `git worktree remove` only runs there),
`rm -rf`s the session dir and kills the tmux window. It deletes a session branch only when
`_sessions_merged` proves its work is on `origin`'s default branch; any other branch is kept,
since it may hold the only copy of the work. Leaving merged branches behind is what lets a dead
`renovate` block `renovate/*` later. "Merged" means the tree is identical to the default
branch, or every commit has a patch-equivalent there (merged or rebased), or — for GitHub
squash merges, which fool both `branch -d` and `git cherry` — the branch's whole diff, built as
one synthetic commit on the merge base, has a patch-equivalent there. Any git error counts as
unmerged. `delete` fetches first (best-effort: offline only means fewer branches count as
merged). It prompts for confirmation only when a worktree is dirty: uncommitted changes, or
commits not on any remote **unless merged**. A squash-merged branch whose remote branch was
deleted has commits on no remote, but its work is safe. A repo with no remote always counts.

`new` and `add` also symlink every worktree's `.claude/agents/*.md` into the session root's own `.claude/agents/`,
because claude only loads project agents from the directory it launches in, and a session launches at the root.
Agents appear on the next claude start; a name already linked from another repo is kept.

`new` and `add` also run `bd init` at the session root, giving the session one **beads**
tracker whose issue prefix is the session name. It sits above the worktrees on purpose: `bd`
finds a `.beads/` by walking up, so every repo in the session shares one issue graph and a
cross-repo ordering constraint is expressible as a real dependency (`bd ready` then withholds
the blocked side, and `bd close` refuses it outright). Flags that matter: `--skip-agents`,
because bd otherwise appends its own managed block to the `CLAUDE.md` just copied from
`sessions.md`; `--init-if-missing`, which makes `add` a no-op and backfills sessions predating
this; `--skip-hooks`, since the repo those hooks would land in is deleted immediately after
(below); and a subshell `cd` rather than `bd -C`, which does not pick up `beads.role`
(GH#2950). No bd on PATH means both helpers no-op.

`bd init` also `git init`s the session root and commits a `.gitignore` — unconditionally, with
no flag to opt out (`--skip-hooks` skips only the hooks). `_sessions_beads_init` deletes both
right after, guarded on `.beads/` existing. The session root is a container for worktrees, not
a repo, and a repo there makes starship report a branch on every prompt and lists every
worktree as untracked. bd needs none of it — deps, `ready` gating, `close` refusal and walk-up
discovery from inside a worktree all work with no repo in scope — with one exception:
`beads.role` lives in git config, so `templates/gitconfig.j2` carries a global
`[beads] role = maintainer` for the lookup to land on (a repo-local `beads.role` still wins).
Without that fallback every read command prints a `beads.role not configured` warning.
`delete`'s `find -mindepth 2` stays regardless: sessions predating this still have that root
`.git`, and it is a worktree of nothing, so sweeping it in makes every teardown claim unsaved
work. Since `rm -rf` takes the tracker with the session, `delete` warns on open beads the same
way it warns on dirty worktrees, and one confirmation covers both. Counts are grepped down to
a bare integer because bd interleaves throttled tips with its output.

## Setup, `reinit` and the init hook

Everything a session root gets besides worktrees — the `CLAUDE.md` symlink, the beads tracker,
the agent links and the init hook — lives in `_sessions_setup`, and every step in it is
idempotent. `new`, `add` and `adopt` call it; `reinit` calls *only* it (plus the tmux window),
so a change to any of that machinery reaches existing sessions without recreating them.
`reinit` with no argument targets the session `$PWD` sits in, falling back to fzf. Only
`reinit` infers from `$PWD`: `delete` doing so would make the session you stand in a
one-keystroke target. Agent linking also prunes dangling links, so an agent removed from a
worktree disappears from the root on the next `reinit`.

`SESSIONS_INIT_HOOK` names a shell function run last in `_sessions_setup` as
`$SESSIONS_INIT_HOOK <session> <session-dir>` — the place for machine-specific session setup
(work credentials, extra links, env files). Define the function and export the variable in
`dots/shell/local.zsh` or any file sourced before an interactive `sessions` call. The hook must
be idempotent, since `reinit` re-runs it. An undefined function or a non-zero exit warns but
never fails the session.

## adopt

`adopt` turns an existing branch into a session. It fzf-picks repos, runs `_sessions_fetch` on
them (the branch list and the adopted ref both come from remote-tracking refs), then
fzf-picks a branch from the union of their local branches and
branches on **any** remote. Repos in one session can name remotes differently — `origin` in
one, only `upstream` in another, a fork alongside — so `origin` is not assumed. The session
name is the branch with `/` flattened to `-` (`feat/x` lands at `~/sessions/feat-x`). Repos
lacking the branch are skipped. A local branch is checked out as-is; a remote-only one gets a
local branch **tracking** `<remote>/<branch>` — unlike `new`'s `--no-track`, since here the
remote branch *is* the work. `_sessions_remote_branch` picks the remote: `origin` if it has the
branch, else the first match alphabetically, with a warning when several remotes do. Git refuses a branch
already checked out elsewhere (including the original checkout), and that error is surfaced.
Adopting into an existing session name adds to it. Repos holding the branch are preflighted
together before the session dir is created; if none can adopt it, no dir is left behind.

Overridable: `SESSIONS_ROOT`, `SESSIONS_TMUX`, `SESSIONS_TEMPLATE`, `SESSIONS_SCAN_DEPTH`,
`SESSIONS_INIT_HOOK`, `SESSIONS_BRANCH_PREFIX`.

Note tmux target names are passed as `"=${SESSIONS_TMUX}"` — the quotes matter, unquoted `=foo`
hits zsh's equals-expansion.

