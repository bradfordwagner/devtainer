Pick up the open Renovate PRs on the `bradfordwagner/ansible-role-*` repos, merge the ones the user confirms, and follow each through its Galaxy release. An optional argument names one role (or a unique substring, e.g. `argo`, `wiz`) to restrict the run to that role.

Renovate (`bradfordwagner/renovate`, preset `ansible-role`) does the version checking: it runs daily at 11:00 UTC and opens one PR per update. Do not check upstreams by hand or bump versions yourself. Everything here goes through `gh -R`, so no local clones are needed.

## Phase 1 — find

1. List the roles: `gh repo list bradfordwagner --limit 200 --json name -q '.[].name | select(startswith("ansible-role-"))'`. Narrow to the argument if one was given.
2. For each role, list the open Renovate PRs: `gh pr list -R bradfordwagner/<role> --author app/bradfordwagner-renovate --state open --json number,title,labels,headRefName,statusCheckRollup,url`.
3. Also list `renovate/*` branches with no open PR: `gh api repos/bradfordwagner/<role>/branches --paginate -q '.[].name | select(startswith("renovate/"))'`, minus each PR's `headRefName`. These are usually held back by `prConcurrentLimit` and show on the repo's Dependency Dashboard issue. Report them; do not open PRs for them.
4. Report one markdown table: `Role | PR | Title | Release | CI`. `Release` is yes when the PR carries the `release` label. Only those PRs cut a new Galaxy version on merge. The rest (GitHub Actions, CI base image) change CI only.

If nothing is open, say so and offer to start Renovate early for the roles in scope: `gh workflow run renovate.yaml -R bradfordwagner/renovate -f repository=bradfordwagner/<role>`. Start it only on a yes.

## Phase 2 — confirm

Ask a yes/no question per PR via `AskUserQuestion`, "Yes" first, up to 4 questions per call; batch the calls rather than skip any. Name the role, the update and whether it releases. Do not merge a PR without its explicit yes. A merge with the `release` label pushes a tag and a public Galaxy release.

Before asking, read the PR body (`gh pr view <n> -R <repo> --json body`). Flag any PR whose CI is red, and any `config.yaml` base-image bump whose `builds:` OS list might not match what the new tag publishes (the PR body notes this).

## Phase 3 — merge

For each repo with approved PRs, use the `renovate-merger` agent when it is available (sessions in the `renovate` repo). Otherwise, merge one PR at a time:

1. Fetch the gate once: `gh api repos/bradfordwagner/renovate/contents/.claude/skills/renovate/merge-ready.sh -q .content | base64 -d > <scratchpad>/merge-ready.sh`.
2. Run `bash <scratchpad>/merge-ready.sh bradfordwagner/<role> <n>`. Merge only when it exits 0: `gh pr merge <n> -R bradfordwagner/<role> --squash`. Never pass `--delete-branch`; the repo setting deletes the branch.
3. Re-run the gate before each later PR in the same repo. If a PR goes conflicted after an earlier merge, stop on it and report it. Renovate rebases it on its next run, or tick its rebase box on the Dependency Dashboard.

## Phase 4 — release (PRs with the `release` label only)

Each merge starts `.github/workflows/release.yml`, which tags the next patch version and dispatches `container_tags.yml`. Watch both runs; background the watches when several roles are releasing.

1. `gh run list -R <repo> --workflow release.yml --limit 3 --json databaseId,headSha,status,conclusion`. Pick the run for the PR's merge commit (`gh pr view <n> -R <repo> --json mergeCommit`), then `gh run watch <id> -R <repo> --exit-status`. Read the new tag from the run summary or `gh api repos/<repo>/tags -q '.[0].name'`.
2. `gh run list -R <repo> --workflow container_tags.yml --event workflow_dispatch --limit 3 --json databaseId,headBranch,status`. Pick the run whose `headBranch` is the new tag, then watch it the same way. Its `publish` job pushes to Galaxy.
3. Verify: `curl -s "https://galaxy.ansible.com/api/v1/roles/?namespace=bradfordwagner&page_size=50"` and confirm the role shows the new tag at the top of `summary_fields.versions`. Use the Galaxy name from `meta/main.yml`'s `galaxy_info.role_name` (`gh api repos/<repo>/contents/meta/main.yml -q .content | base64 -d`); it can differ from the repo name, e.g. `ansible-role-argo` publishes as `argo`.

If any run fails, stop on that role and report the failing run's URL. Continue with the other roles.

## Phase 5 — report

One table: `Role | PR | Merged | Tag | Galaxy`. Mark PRs without the `release` label as `no release`. Add one line per anything unexpected (blocked PR, failed run, branch without PR).
