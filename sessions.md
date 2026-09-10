# Session

This directory is a work session. Each subdirectory is a git worktree of a
different repo, all checked out on the same branch — the session name, which is
also this directory's name.

- Work across the repos as one change; keep the branch name consistent.
- Commit in each repo separately.
- The worktrees are linked to their original checkouts elsewhere on disk; don't
  delete them by hand, use `sessions delete`.
