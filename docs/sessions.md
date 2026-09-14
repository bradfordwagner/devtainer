# sessions (multi-repo worktrees)

`dots/shell/sessions.sh` defines the `sessions` function: `sessions` fzf-picks the verb,
`sessions new|add|delete` skips straight to it.

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
not inherit the base as its upstream. That fetch is **load-bearing and checked**: if it fails,
`_sessions_add_worktree` reports and returns 1 rather than branching from whatever was last
fetched, and `new`/`add` propagate that as a non-zero exit instead of a half-built session.
A repo with no `origin` is the one exemption — nothing to fetch, and `HEAD` is the base — so
the guard tests for the remote before treating a fetch failure as one. Both verbs iterate
`${(f)repos}` rather than piping into `while`, or the failure flag would die in the subshell.

Nothing about this touches the *original* checkout: `git worktree add` leaves its HEAD, branch
and working tree alone, so it stays readable for diffs while a session is live. The only thing
that moves there is `origin/*`, which the fetch advances. Git will refuse to check the session
branch out in the original while a worktree holds it — `log`/`diff`/`show` are unaffected. `delete` unregisters the worktrees from their *original*
checkouts (resolved via `--git-common-dir`, since `git worktree remove` only runs there),
`rm -rf`s the session dir and kills the tmux window — but never deletes branches, which may
hold the only copy of unpushed work. It prompts for confirmation only when a worktree is dirty
(uncommitted changes, or commits not on any remote — so a repo with no remote always counts).

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

Overridable: `SESSIONS_ROOT`, `SESSIONS_TMUX`, `SESSIONS_TEMPLATE`, `SESSIONS_SCAN_DEPTH`.

Note tmux target names are passed as `"=${SESSIONS_TMUX}"` — the quotes matter, unquoted `=foo`
hits zsh's equals-expansion.

