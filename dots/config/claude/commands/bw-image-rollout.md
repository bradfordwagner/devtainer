Cut a new tag of one of our container images, then propagate that tag to every repo that consumes it — opening a PR per consumer, waiting out CI, and merging what goes green. Arguments: `<base|ansible> [patch|minor|major]`. Default bump is `patch`. With no arguments, ask which image.

This does hard-to-reverse, publicly-visible things (tag pushes, PR merges, image publishes). Confirm before phase 2 and again before phase 5.

## The image chain

```
container-base  ->  container-ansible  ->  18 consumers
 (ghcr.io/.../base)   (ghcr.io/.../ansible)    5 containers + 13 roles
```

| Repo | Local path |
|---|---|
| container-base | `~/workspace/github/bradfordwagner/containers/mirrors/bradfordwagner.container.mirrors.base` |
| container-ansible | `~/workspace/github/bradfordwagner/containers/custom/bradfordwagner.container.custom.ansible` |
| ansible containers | `~/workspace/github/bradfordwagner/containers/ansible/bradfordwagner.container.ansible.*` |
| roles | `~/workspace/github/bradfordwagner/ansible_roles/bradfordwagner.ansible.role.*` |

Both image repos build via dagger (`container_branches.yml` on branch push, `container_tags.yml` on tag push). Consumers pin the image in `config.yaml` under `upstream:` (and sometimes `runtime:`).

## Why this exists

`container-ansible`'s `install_ansible.sh` `debian_deps()` runs `apt-get update` and **never clears `/var/lib/apt/lists/*`**, so the published image ships the apt index from its build time. When Debian rolls a package forward and prunes the old `.deb` from the pool, every downstream test installing that package 404s until the image is rebuilt. (`container-base` does not have this problem — `scripts/debian.sh` ends with `rm -rf /var/lib/apt/lists/*`.)

So a "rebuild with no source change" is a legitimate, useful release here. If `install_ansible.sh` is ever fixed to clear its lists, this whole failure class goes away and rollouts become version-bump-only.

### Recognising the symptom

The tell is **the same job failing identically across many unrelated repos** — one repo broken is a repo bug, ten repos broken on the same OS/arch is an image bug. The decisive evidence is a package 404 during dependency install, e.g.:

```
E: Failed to fetch http://deb.debian.org/debian/pool/main/u/unzip/unzip_6.0-29_arm64.deb  404  Not Found
```

Confirm it in one command — if the live index names a *different* version than the error does, the image's baked index is stale:

```
curl -s http://deb.debian.org/debian/dists/<suite>/main/binary-<arch>/Packages.gz \
  | gunzip | grep -A3 "^Package: <pkg>$"
```

Do **not** waste time on these dead ends (all were checked and cleared once):
- The `andrewrothstein.unarchivedeps` role dependency — it pins **no** package versions, so bumping it fixes nothing. A repo already on its latest release still failed.
- The consumer's own base image pin — it was already the newest tag.
- Retrying — the old `.deb` is genuinely gone from the pool, so it fails identically every time. One rerun is enough to prove it isn't transient.

## Phase 1 — discover (read-only)

Do not hardcode the consumer list; derive it, so new repos are picked up for free.

1. **`git fetch origin` every repo first**, before reading anything out of it.
2. Read the pins from **`origin/main`, not the working tree**: `git show origin/main:config.yaml`. A local checkout can be on a feature branch or hundreds of commits behind, and reading it gives a pin that is simply wrong — this has produced a bogus discovery table more than once (a repo reported as pinned `6.4.0` was actually on `6.5.0` upstream, and another was read off a stale feature branch entirely). `origin/main` is the only authoritative answer to "what is this repo pinned to."
3. Record any block whose `repo:` **or** `image:` is `ghcr.io/bradfordwagner/<target>`, plus that block's `tag:`. A repo can have more than one (e.g. `bradfordwagner.container.ansible.go.builder` pins ansible under `upstream:` *and* base under `runtime:` — both need bumping).
4. Separately note each repo's **local** state: current branch, whether the tree is clean, and whether local `main` is behind `origin/main` (`git rev-list --count main..origin/main`). Surface anything not on a clean, current `main` to the user — do not auto-fix, stash, or discard. A repo parked on someone's in-progress branch is a question for the user, not a thing to steamroll.
5. Report: a table of `Repo | Pin (origin/main) | Local branch | Clean? | Behind by`, and the count of consumers found. Call out explicitly any repo whose local state will need attention before phase 5 can branch from a current `main`.

Repos that don't reference the image are not consumers — mirrors repos build from public upstreams. `mirrors.helm/workflow.yaml` has a legacy `quay.io/bradfordwagner/ansible:3.6.2` reference that is **not** live; ignore it.

## Phase 2 — baseline (read-only, do not skip)

For each consumer, record the conclusion of the most recent `main` CI run: `gh run list --branch main --limit 3`.

This is what lets phase 5 tell "my bump broke it" apart from "it was already broken." Without it you will waste time triaging pre-existing failures. `bradfordwagner.container.ansible.devtainer` is red on `main` for its own reasons (a hardcoded `/home/bwagner/linuxbrew` path) and that is expected.

Report the baseline as `Repo | main CI` and call out anything already red.

## Phase 3 — cut the image release

Confirm with the user before this phase.

1. `cd` to the image repo. `git fetch origin`, checkout `main`, `git merge --ff-only origin/main`.
2. If the target is `ansible` and its own `upstream.tag` (the base pin) is not the newest base tag, bump it first: branch `chore/base-<ver>`, commit, push, PR, wait for CI, merge. Then continue on the updated `main`.
3. Pick the next tag from `git tag --sort=-v:refname` and the requested bump level. A pure rebuild or dependency bump is a **patch**.
4. Before tagging, check whether the OS matrix needs updating — see "OS audit" below. An OS list change is a **minor**, not a patch.
5. `git tag -a <new> -m "<reason>"`, `git push origin <new>`.
6. Watch the tag build: `gh run list --branch <new>`, then `gh run watch <id> --exit-status`.

## Phase 4 — gate on the registry, not the build

**This is the step that prevents the most common failure.** A consumer PR pushed before the image finishes publishing fails with `ghcr.io/bradfordwagner/<image>:<tag>-<os>: not found`. The build job going green is not sufficient — poll the registry until every expected OS variant is actually listed:

```
TOKEN=$(curl -s "https://ghcr.io/token?service=ghcr.io&scope=repository:bradfordwagner/<image>:pull" \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['token'])")
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://ghcr.io/v2/bradfordwagner/<image>/tags/list?n=1000"
```

Expect one manifest tag per OS variant plus per-arch tags (recent releases: ~29 tags for ansible across 10 OS variants, ~35 for base across 12). Compare the published OS variant list against the consumers' `builds:` lists — **if an OS family disappeared between releases, bumping the tag alone breaks those consumers**, and their `builds:` must be updated in the same PR.

Only proceed once the tags are live.

## Phase 5 — fan out to consumers

Confirm with the user before this phase. Use **parallel subagents**, batched about 5-7 repos each — this is 18 repos and doing it inline is slow. Give each agent a self-contained brief: the repo list, why the bump exists, the exact commit message, and hard limits (no merging, no tagging, only `config.yaml`).

Per consumer:
1. `git fetch origin`, checkout `main`, `git merge --ff-only origin/main`. Dirty tree or non-fast-forward → skip and report; never stash or discard.
2. Branch `chore/<image>-<newtag>`. Don't reuse old branches — these repos squash-merge, so stale branches drag in already-merged history.
3. Edit **only** the `tag:` line belonging to the matching `repo:`/`image:` anchor in `config.yaml`. Verify with `git diff` that exactly one line changed (two, for a repo with two pins).
4. Commit `chore: <image>=<newtag>` with a body explaining the refresh, push with `-u`, and `gh pr create`.

Then **verify the agents' work yourself**: for every repo confirm `git diff main...HEAD --name-only` is only `config.yaml`, and that no role version variable in `defaults/main.yml` or `test.yml` was touched.

Watch out for: `pack` and `terraform` each exist as **both** a container repo and a role repo — always disambiguate which one you mean.

## Phase 6 — wait, triage, merge

Confirm with the user before merging.

1. Poll each consumer's run: `gh run list --branch <branch> --limit 1`.
2. For failures, get the decisive line with `gh run view <id> --log-failed` piped through `grep` — these logs are enormous, never dump them. Classify:
   - `...:<tag>-<os>: not found` → publish race. `gh run rerun <id> --failed` **once**, then re-evaluate.
   - Same failure present in the phase 2 baseline → pre-existing, not caused by this change. Report it; ask the user whether to merge anyway.
   - Anything else → do not merge that repo; report the error.
3. Merge the green ones: `gh pr merge <n> --squash --delete-branch`.
4. Verify independently afterward: for each repo, `git show origin/main:config.yaml` actually carries the new tag, and `gh pr list --head <branch> --state open` is empty.

Consumers are **not** released by this skill — bumping a CI image pin doesn't change published role content, so no role tags are cut and Galaxy is untouched. Run `/bw-role-update` separately for actual version releases.

## OS audit (phase 3 step 4)

Compare `config.yaml`'s `builds:` list in `container-base` against upstream:

| Distro | Where to check | Rule |
|---|---|---|
| alpine | `hub.docker.com/v2/repositories/library/alpine/tags` | track current stable series |
| debian | `hub.docker.com/v2/repositories/library/debian/tags` | oldstable + stable + testing codenames |
| ubuntu | `hub.docker.com/v2/repositories/library/ubuntu/tags` | the two most recent **LTS** only; skip interim and pre-release codenames |

Adding or removing an OS is a minor bump and requires updating `builds:` in `container-ansible` and in consumers whose matrix names that OS.

## Progress pane (tmux only)

If `$TMUX` is set and the rollout covers more than a handful of repos, stand up a live dashboard before phase 5; skip silently if not in tmux or if the split is refused.

1. Anchor to this session's own pane: `TARGET="${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}"`. Never target the *active* pane — the user may navigate away right after sending the message, and the split would land in the wrong window.
2. `NEWPANE=$(tmux split-window -t "$TARGET" -h -l 56 -P -F '#{pane_id}')`, then address it by that `%N` id for the rest of the session.
3. Write a `targets.tsv` in the scratchpad — one `label<TAB>repo_dir<TAB>branch` row per repo, with `# group` lines as headings — and a small self-contained bash renderer that reads it, calls `gh run list`/`gh run view` per row, and prints one line per repo: status glyph, label, a done/total bar. Keep it to plain bash + `gh --jq` (no `jq` dependency), `sleep 10` between redraws, and a header counting ok/fail/running/pending.
4. Launch it by passing the script to `split-window` as the pane command (step 2), not via `send-keys` — typing into a freshly spawned interactive shell races its startup and the command can be echoed twice or swallowed.
5. Table-driven means you can append rows as PRs open without touching the script. At the end, `tmux send-keys -t "$NEWPANE" C-c` to stop the refresh but leave the final state on screen.

## Phase 7 — report

1. Per-repo outcome: PR URL, merged or not, and the reason for anything left open.
2. Confirm the fix actually worked — name the specific job that was failing before and show it passing now, rather than just reporting "CI green."
3. A **nerd stats** block. Harvest run data live during phases 3-6 (`gh run view <id> --json createdAt,updatedAt,jobs`), since it's far easier than reconstructing it later. Include:
   - total CI runs, total jobs, pass/fail counts
   - summed job duration ("CPU-time") vs wall-clock elapsed, and the resulting parallel speedup
   - the longest single run, named
   - a failure autopsy: how many failures were the publish race, how many pre-existing, how many real
   - dead ends explored before the root cause, and the best red herring

Keep it punchy — a small table and a few lines, not a wall of numbers.
