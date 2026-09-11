# Session

<!-- This file is a symlink to ~/dotfiles/sessions.md, shared by every session.
     Edits here change the template for all of them; there is no per-session
     copy to scribble on. -->

This directory is a work session. Each subdirectory is a git worktree of a
different repo, all checked out on the same branch — the session name, which is
also this directory's name.

- Work across the repos as one change; keep the branch name consistent.
- Commit in each repo separately.
- The worktrees are linked to their original checkouts elsewhere on disk; don't
  delete them by hand, use `sessions delete`.

## Tracking the work

The session root holds a `.beads/` issue database covering every repo in the
session. `bd` finds it by walking up, so it works from inside any worktree, and
issue IDs are prefixed with the session name.

- Track work as beads, not in TodoWrite or a markdown checklist — a bead
  outlives the context window; a todo list in scrollback does not.
- `bd ready` is the answer to "what's next": open issues with no active
  blockers. Ask it before planning, and again whenever direction changes or a
  chunk lands — not once at the start.
- `bd q "<title>"` captures something out of scope in one call, without
  derailing what you're on.
- File the bead when the work appears, not when you start it. **Scope that
  arrives mid-session is the case this gets wrong**: a follow-up you are about
  to do anyway still gets a bead first. Four requests in a row that each go
  straight to code leave a tracker that describes the session you planned, not
  the one you had.
- Anything you find but do not fix is a bead — an untested path, a gap in the
  evidence, a number that did not add up. "I'll mention it in the summary" is
  scrollback, and scrollback is what the tracker exists to outlive.
- Say what you are on: `bd update <id> --status in_progress`. A tracker that
  only ever shows open and closed cannot answer "what was I doing".
- Cross-repo ordering is a dependency, not a comment. `bd dep add <blocked>
  <blocker>` — `bd ready` then withholds the blocked side until the blocker
  closes, which is the whole reason the tracker lives at the session root
  instead of in either repo.
- Close beads as work lands (`bd close <id>`) and name the ID in the commit, so
  the reasoning is reachable from the repo after the session is gone. Close in
  the same turn as the commit that lands it — a batch close at the end means the
  tracker was a record of the work, never the state of it.
- `bd prime` prints the full command reference.

`~/.claude/hooks/bd-ready.sh` runs on every prompt and injects the ready queue,
so the tracker is in front of you whether or not you thought to ask. An empty
ready list while work is plainly in flight means the tracker is stale, not that
there is nothing to do.

The tracker is scoped to the session: `sessions delete` destroys it along with
the worktrees. Anything that has to outlive the session belongs in a commit, an
upstream issue, or a `bd export`.

## Showing the work

Every change ships with evidence that it actually works. Claims like "verified"
or "tested" are not evidence; a command someone else can re-run is.

- Write a runnable script — `evidence.sh` at the session root, or per-repo when
  the checks are repo-local. It must be idempotent, safe to run repeatedly, and
  clean up whatever it creates. Exit non-zero when a check fails.
- Write it up as `evidence.md` (or `evidence.html`) next to the script: what was
  claimed, the command that proves it, the actual output, pass or fail.
- Prefer exercising the real thing — the actual function, the actual manifest —
  over a description of it. Sandbox it so a failed run costs nothing: a temp
  dir, an overridden `SESSIONS_ROOT`, a throwaway namespace.
- A local cluster is a sandbox, and it is the better evidence. Where the session
  owns one, deploy to it for real rather than stopping at `helm template` — the
  `local` k3d pool member this session claimed exists to be broken, and
  `task recreate` is the reset. Remote clusters are never a test target.
- But local does not mean disposable. `dev` is a shared singleton, contested
  with another repo, and it deploys `main` — so a branch "verified" there was
  never your code. Only the cluster this session claimed is yours to break.
- Pin `--kubeconfig` and `--context` on every cluster command, scripted or by
  hand. `~/.kube/config` is hand-managed and points wherever it was last aimed,
  so an unpinned command quietly proves something about the wrong cluster.
- Report failures as failures. A check that could not run is a gap, not a pass;
  say which and why.
- These files are working artifacts of the session, not repo deliverables. Keep
  them at the session root unless the repo genuinely wants them committed.
