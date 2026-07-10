Check all locally cloned `bradfordwagner.ansible.role.*` Ansible role repos for upstream tool updates, then — for whichever ones the user confirms — bump the pinned version and cut a full release. An optional argument names one role (or a unique substring, e.g. `argo`, `wiz`) to restrict the check/release to just that role; with no argument, check all of them.

## Phase 1 — check (read-only)

Default location: `~/workspace/github/bradfordwagner/ansible_roles/bradfordwagner.ansible.role.*` — if not found there, ask where they live.

For each role directory:
1. Read `defaults/main.yml` for the pinned upstream version variable (commonly named `<prefix>_ver` or `<prefix>_version`).
2. Determine the upstream source:
   - Check `vars/main.yml` and `tasks/main.yml` for a `repo: owner/name` entry (the `go-releaser-install` convention) or a `_mirror:` pointing at a GitHub releases URL — these map to a GitHub repo.
   - Check the role's `CLAUDE.md` if present — some roles document non-GitHub upstreams with exact instructions on how to check the latest version.
   - `bradfordwagner.ansible.role.golang` tracks a Go minor line (e.g. `"1.26"`) and auto-resolves the latest patch at install time — compare against `https://go.dev/dl/?mode=json&include=all` (stable minors only) and flag only if a newer *minor* line exists, not a newer patch.
   - `bradfordwagner.ansible.role.wiz` has no public GitHub releases page. List the S3 bucket via `curl -s https://downloads.wiz.io/v1/wizcli/manifest.json`, extract version-looking key prefixes (`v1/wizcli/X.Y.Z/...`), and take the highest semver directory that actually contains real binaries (not just a `RELEASE_NOTES` stub) as the latest version.
   - `bradfordwagner.ansible.role.go.releaser.install` is a generic installer helper with no fixed upstream of its own — skip it.
3. For GitHub-hosted upstreams, query `https://api.github.com/repos/<owner>/<repo>/releases/latest` for the current tag.
4. Compare pinned vs latest and report the outcome per role in a single markdown table: `Role | Upstream | Current | Latest | Update?`.

If nothing needs updating, stop here and say so.

## Phase 2 — confirm

If any roles need updates, ask the user which of them to release (default suggestion: all that need it). Do not proceed to phase 3 without this confirmation — it does hard-to-reverse, publicly-visible things (PR merges, tag pushes, public Galaxy releases).

## Phase 3 — release (per confirmed role)

Each role is its own git repo (remote `bradfordwagner/ansible-role-<name>` on GitHub, local path as above) with CI wired as:
- `.github/workflows/container_branches.yml` — runs on every branch push, builds+tests the role across its OS/arch container matrix.
- `.github/workflows/container_tags.yml` — runs on tag push, rebuilds the matrix, then runs a `publish` job (`robertdebock/galaxy-action`) that publishes the role to Ansible Galaxy under namespace `bradfordwagner`.

Steps, for each confirmed role:
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

Report, per role: the PR URL, the release tag, and the Galaxy confirmation.
