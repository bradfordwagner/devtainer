Check all locally cloned `bradfordwagner.ansible.role.*` Ansible role repos for upstream tool updates, then — for whichever ones the user confirms — bump the pinned version and cut a full release. An optional argument names one role (or a unique substring, e.g. `argo`, `wiz`) to restrict the check/release to just that role; with no argument, check all of them.

## Phase 1 — check (read-only)

Default location: `~/workspace/github/bradfordwagner/ansible_roles/bradfordwagner.ansible.role.*` — if not found there, ask where they live.

For each role directory:
1. Sync the repo before reading anything from it: `git fetch origin`, then check the current branch (`git branch --show-current`).
   - If it's the default branch (`main`): fast-forward it to `origin/main`. If the working tree has uncommitted changes that block the fast-forward, stop and ask the user what to do for that repo rather than stashing/discarding automatically.
   - If it's a non-default branch: stop and ask the user what to do for that repo before proceeding — options like switch to `main` and fast-forward (stashing or leaving uncommitted changes as they choose), check upstream against the current branch as-is, or skip this repo entirely. Don't guess; this decides which commit the version check reads from.
2. Read `defaults/main.yml` (from the now-synced checkout) for the pinned upstream version variable (commonly named `<prefix>_ver` or `<prefix>_version`).
3. Determine the upstream source:
   - Check `vars/main.yml` and `tasks/main.yml` for a `repo: owner/name` entry (the `go-releaser-install` convention) or a `_mirror:` pointing at a GitHub releases URL — these map to a GitHub repo.
   - Check the role's `CLAUDE.md` if present — some roles document non-GitHub upstreams with exact instructions on how to check the latest version.
   - `bradfordwagner.ansible.role.golang` tracks a Go minor line (e.g. `"1.26"`) and auto-resolves the latest patch at install time — compare against `https://go.dev/dl/?mode=json&include=all` (stable minors only) and flag only if a newer *minor* line exists, not a newer patch.
   - `bradfordwagner.ansible.role.wiz` has no public GitHub releases page. List the S3 bucket via `curl -s https://downloads.wiz.io/v1/wizcli/manifest.json`, extract version-looking key prefixes (`v1/wizcli/X.Y.Z/...`), and take the highest semver directory that actually contains real binaries (not just a `RELEASE_NOTES` stub) as the latest version.
   - `bradfordwagner.ansible.role.go.releaser.install` is a generic installer helper with no fixed upstream of its own — skip it.
4. For GitHub-hosted upstreams, query `https://api.github.com/repos/<owner>/<repo>/releases/latest` for the current tag.
5. Compare pinned vs latest and report the outcome per role in a single markdown table: `Role | Upstream | Current | Latest | Update?`.

If nothing needs updating, stop here and say so.

## Phase 2 — confirm

If any roles need updates, ask a yes/no question per role via `AskUserQuestion` — each role gets its own explicit answer (don't lump them into one "which of these?" question), so the user can say yes to some and no to others without a clarifying round-trip. Default/first option is "Yes". `AskUserQuestion` allows up to 4 questions per call; if more than 4 roles need updates, batch the calls (4 at a time) rather than skipping any. Do not proceed to phase 3 for a role without its explicit yes — this does hard-to-reverse, publicly-visible things (PR merges, tag pushes, public Galaxy releases).

## Phase 2.5 — release progress pane (tmux only)

If `$TMUX` is set and at least one role was confirmed, stand up a live dashboard pane before starting phase 3. Skip this whole phase (no pane, just narrate progress inline as usual) if not running inside tmux.

1. Capture the current pane as the split target: `tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'`.
2. Split a dashboard pane and capture its id directly: `NEWPANE=$(tmux split-window -t <target> -h -l 50 -P -F '#{pane_id}')`.
3. In the scratchpad directory, write `role-update-status.tsv` with one tab-separated line per `<confirmed role> x <step>`, all starting `pending`:
   `<role>\t<step_num>\t<step_label>\t<status>\t<start_epoch>\t<end_epoch>`
   Steps are the 10 from phase 3: sync-main, branch, edit-version, commit-pr, ci-watch-branch, merge, tag, push-tag, ci-watch-tag, verify. `status` is one of `pending|active|done|failed`; epochs are `0` until set. Also write `role-update-started` containing the overall start epoch.
4. Write a small self-contained bash renderer to `role-update-progress.sh` in the scratchpad (no `jq` — it must run unattended, so keep it to `awk`/`read`/plain bash): a `while true` loop that clears the pane, prints a header with elapsed time since the overall start epoch, then per role a done/total progress bar plus each step with a glyph (✓ done, a spinner frame for `active`, `○` pending, `✗` failed), and the step's duration once it's done. `sleep 1` between redraws.
5. Launch it in the new pane: `tmux send-keys -t "$NEWPANE" "bash <scratchpad>/role-update-progress.sh" Enter`.
6. During phase 3, keep the status file current: rewrite it (it's small) whenever a step starts (`active` + start epoch) or finishes (`done`/`failed` + end epoch). The pane picks up the change on its next redraw — no further tmux calls needed mid-release.

## Phase 3 — release (per confirmed role)

Each role is its own git repo (remote `bradfordwagner/ansible-role-<name>` on GitHub, local path as above) with CI wired as:
- `.github/workflows/container_branches.yml` — runs on every branch push, builds+tests the role across its OS/arch container matrix.
- `.github/workflows/container_tags.yml` — runs on tag push, rebuilds the matrix, then runs a `publish` job (`robertdebock/galaxy-action`) that publishes the role to Ansible Galaxy under namespace `bradfordwagner`.

Steps, for each confirmed role (if a progress pane is running per phase 2.5, mark the matching step `active`+start-epoch before it begins and `done`/`failed`+end-epoch right after — rewrite `role-update-status.tsv` at each transition):
1. `cd` into the role directory. `git fetch origin`, checkout `main`, fast-forward merge to `origin/main` — local `main` is often stale even if a local feature branch looks up to date.
2. Create a new branch off the freshly-synced main, e.g. `chore/bump-<tool>-version`. Don't reuse an old `feature/upgrades`-style branch — these repos squash-merge PRs, so old feature branches go stale/diverge from main after merge and reusing one silently drags in unrelated already-merged history.
3. Edit the version variable in `defaults/main.yml` (per what phase 1 found). If `defaults/main.yml` also has an embedded per-version checksums map (e.g. `azure.blob.cli`), add the new version's checksums too — most roles don't pin checksums and can skip this.
4. Commit as `chore(deps): bump <tool> from <old> to <new>`, push with `-u`, and `gh pr create` with a short summary + a test-plan checkbox for CI.
5. Watch CI: `gh run list --branch <branch>` to get the run id, then `gh run watch <id> --exit-status`. If it fails, stop and report the failure for that role — do not merge, and continue with the other confirmed roles independently.
6. If green, `gh pr merge <n> --squash --delete-branch`.
7. Checkout and fast-forward `main` again. List tags with `git tag --sort=-v:refname` — release tags on these repos are plain semver (no `v` prefix) and versioned independently from the upstream tool's own version. A plain dependency-version bump is a patch release by precedent; only bump minor/major if the merged diff also includes a feature-level change (check `git log --oneline --all --decorate` against past tags if unsure).
8. `git tag -a <new-tag> -m "<same message as the bump commit>"`, then `git push origin <new-tag>` — this triggers `container_tags.yml`.
9. Watch that run the same way (`gh run list --branch <new-tag>`, then `gh run watch <id> --exit-status`); it includes the `publish` job that pushes to Galaxy.
10. Verify: `curl -s "https://galaxy.ansible.com/api/v1/roles/?namespace=bradfordwagner&page_size=50"` and confirm the role's Galaxy `name` (from `meta/main.yml`'s `galaxy_info.role_name` — this can differ from the repo name, e.g. repo `ansible-role-argo` publishes as `argo`) shows the new version at the top of `summary_fields.versions`.

If releasing multiple roles, run their CI/release watches in parallel (background the `gh run watch` calls) rather than doing them fully sequentially.

## Phase 4 — final report

Once every confirmed role has finished (released or failed):

1. If a progress pane is running: let it redraw once more with the final state (everything `done` or `failed`), then stop its refresh loop without closing the pane — `tmux send-keys -t "$NEWPANE" C-c` — so the finished dashboard stays on screen for reference.
2. From `role-update-status.tsv`, compute:
   - Total wall-clock elapsed since the overall start epoch.
   - Per-step duration for every role.
   - The single slowest step overall — that's the headline bottleneck (name role, step, duration, and its share of total wall-clock time).
   - Total time spent in the two `ci-watch-*` steps vs. everything else — CI wait is usually the dominant cost, call it out explicitly if it's >50% of wall-clock.
   - If roles released concurrently, the parallelism payoff: sum of all per-role durations vs. actual wall-clock elapsed.
3. Close out the chat response with:
   - The existing per-role report (PR URL, release tag, Galaxy confirmation).
   - A "Nerd stats" block: total elapsed, roles released, PRs merged, tags pushed, the bottleneck step called out by name, and the CI-wait-vs-mechanics split. Keep it tight — a small table or a few punchy lines, not a wall of numbers.
