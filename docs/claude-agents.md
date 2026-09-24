# Claude Code integration

Everything under `dots/config/claude/` — slash commands, subagents, agent scripts,
keybindings — is **copied** (not symlinked) into `~/.claude/` by
`tasks/install-claude.yml`. Re-run `task bb` to deploy any change here.

Custom slash commands live in `dots/config/claude/commands/*.md` and are copied (not symlinked) to `~/.claude/commands/` by `tasks/install-claude.yml`. Re-run `task bb` to deploy new commands.

Subagents live in `dots/config/claude/agents/*.md` and are copied to `~/.claude/agents/` by
the same task. Name them with a `bw-` prefix — `~/.claude/agents/` is a flat namespace shared
with plugins and built-ins, so the prefix is what marks an agent as ours. One file per agent,
YAML frontmatter (`name`, `description`, `model`, `color`, `tools`) then the prompt as the body.
The `description` is what the main agent matches on when deciding whether to delegate, so it
carries the trigger conditions and worked examples; the body carries the actual instructions.
Re-run `task bb` to deploy.

The agent copy is gated on `claude_agents_enabled` (default true in `variables.yml`). A machine
that deploys agents from another repo sets it false in its gitignored `variables.local.yml` —
only the agent tasks skip; commands, scripts, hooks and keybindings still install, which matters
because those agents may depend on `~/.claude/scripts/`. A work machine does exactly this: a
separate dotfiles repo owns `~/.claude/agents/` there with its own prefixed set, and since
ansible `copy` never removes, that repo also sweeps any `bw-*.md` this one left behind. Two
repos writing that flat namespace unguarded means the last playbook to run wins, silently.

Pin `model:` explicitly rather than using `inherit`. `settings.json` sets the session model to
`opus[1m]`, so `inherit` bills every subagent run at the top tier with a 1M window — wrong for
agents whose reasoning already lives in their prompt and whose inputs are a few hundred lines.
Start at `haiku` and move up only when an agent demonstrably needs it: the tier that matters is
the one that can follow a "precision over volume" instruction, since a report full of plausible
non-findings costs more attention than it saves. Escalate on evidence, not on suspicion.

Then sort by **blast radius**, not by domain. An agent whose bad output you read before acting
on it (a report, a plan) is one you backstop yourself, so the tier can stay low. An agent that
mutates real infrastructure has no such backstop, and its hardest instructions are *restraints*
— "only the labels you were given", "stop and report rather than improvise", "never fabricate a
result" — which is exactly what smaller models hold worst.

Available subagents:
- `bw-accountant` (haiku) — maintains `ledger.md`: what sessions cost, which models spent
  it, which work item it went to. Appends a row per session and re-derives the totals at the
  top (headline, by-model with share-of-spend, by-work-item) rather than incrementing them,
  since one feature usually spans several sessions and the by-item subtotal is the number
  that gets quoted. Every figure comes from `~/.claude/scripts/session-usage.sh` — it never
  estimates, because a wrong cost is not visibly wrong to whoever reads it later. On request
  it posts a summary onto a named GitHub (`gh`) or Linear (MCP) issue; it discovers the
  tooling rather than assuming it, and never posts to a ticket the user did not name.
  Also tracks **context**: peak tokens against the model window, flagged only at 50%
  and 80%. Deliberately understated — every current model is 1M except haiku at 200K,
  so headroom is rarely binding and a verdict firing on every row is noise. There is
  no long-context premium either, so a roomy window costs nothing: a low peak beside a
  high bill means the driver is turn count re-reading a cached prefix, which is what
  the ledger says instead. Table columns are padded to align in a plain editor; these
  files get read in nvim.
- `bw-k8s-author` (sonnet) — writes and refactors Kubernetes manifests in whatever form the
  target repo already uses: Helm charts, kustomize bases/overlays, or plain YAML. It identifies
  the shape first and stays in it — a kustomize overlay bolted onto a Helm repo doubles the
  places a value can come from and nobody remembers which one won — defaulting to Helm only
  for new work with no precedent. The environment layering is built in: the base is the complete
  working configuration, every environment layer carries only genuine deltas, and an empty env
  file is a correct outcome rather than an omission. The base is chosen **per field**, not per
  environment: `requests` are reserved by the scheduler so the smallest environment's figures
  belong in the base, while `limits` cost nothing until hit so the largest environment's do —
  mixing them left `charts/cert-manager` needing no override at all.

  It exists because environment files rot toward duplication invisibly — a block copied into two
  env files reads fine the day it is written, and six months later one side has been tuned and
  the other has not. Both tools merge maps, so the copy was never needed; **lists** are the
  exception it checks by hand, and each tool bites differently: Helm replaces a list wholesale,
  kustomize merges only lists with a patch merge key (`containers` by name, `ports` by
  `containerPort`) and replaces `command`/`args`/anything under a CRD, and a JSON 6902 patch
  never merges at all — it addresses an index, so it breaks silently when the list reorders.
  Under server-side apply the equivalent trap is field ownership: a dropped field is removed
  only if your field manager owned it.

  Its hardest rule is that a refactor must render **byte-identical** before and after — it
  snapshots `helm template` or `kustomize build` for every base/env pair, diffs, and reports the
  diff rather than explaining it away. It validates per pair (`helm lint` **and** `helm template`,
  since lint alone misses a template that fails to render; `kubeconform -strict` or a
  **server-side** dry run for schema) and never applies to a cluster — that is Argo CD's job or
  the user's. Also knows the Argo CD traps: that `charts/app-of-apps` per-app overrides replace
  wholesale rather than merging, that value files cannot carry per-cluster facts (Argo CD renders
  server-side, so the slug and `$USER` travel as helm parameters from `charts/root-app`), that a
  CRD over 262144 bytes needs `ServerSideApply`, and that a sync wave is a head start rather than
  a gate.

#### Agent scripts: `dots/config/claude/scripts/`

Tools the subagents invoke, copied to `~/.claude/scripts/` by `tasks/install-claude.yml`
(`.sh` gets 0755, everything else 0644). Deliberately **not** `dots/shell_scripts/`: that dir
is on `PATH` and is for the human's own commands, while these are an implementation detail of
a prompt and would only be clutter at the shell. Agents call them by absolute path
(`~/.claude/scripts/foo.sh`), so nothing here needs to be on `PATH`. Re-run `task bb` to
deploy.

#### `session-usage.sh`

`dots/config/claude/scripts/session-usage.sh` tallies one session's tokens and cost from its
JSONL transcript, defaulting to `$CLAUDE_CODE_SESSION_ID` (the live session) and taking
`--session`/`--project`/`--json`. It exists because the transcript records usage but never
cost, and because the obvious way to add it up is wrong three times over:

- **Duplicate turns.** One assistant turn is written once per content block, and every copy
  repeats the *same* cumulative usage — summing lines roughly doubles the bill. Deduped on
  `message.id` (in one real session: 92 lines, 43 actual turns).
- **Subagent spend.** Subagent turns live in `<session>/subagents/*.jsonl`, absent from the
  main transcript entirely, so reading only the main file under-reports exactly the delegated
  work that costs most.
- **Synthetic turns.** `<synthetic>` entries are harness-generated and carry no usage.

Prices are a jq table of per-MTok rates (cache write 1.25× input at 5m TTL / 2× at 1h, cache
read 0.1×; no long-context premium on current models). That table is the only part that rots —
a model missing from it is reported `[UNPRICED]` with a warning that the total is an
understatement, never silently costed at zero. Exit 2 is the tool failing to run (no `jq`, no
transcript), distinct from a bad-usage exit 1. Needs only `jq`.

It also reports context: per-turn peak (input + cache read + cache write), the model window,
and % used. The session-level percentage is the **worst** per-model ratio, so a haiku turn
near its 200K limit is not hidden by an opus turn's 1M window — haiku being the one model
where the flag earns its place, since everything else is 1M at standard pricing.

And it reports **growth** — context in the session's last quarter minus its first —
computed over main-session turns only, since subagents start fresh and interleave with
the parent; pooling them made one real session report *negative* growth. That is what
separates "high peak, plateaued" (a large working set) from "high peak, still climbing"
(the one that overflows next time), which a peak alone cannot tell you.

Two things it cannot know: the transcript lags the in-flight turn, so a live session's last
few turns are missing; and cache **writes** cannot be attributed to what caused them.

Keybindings live in `dots/config/claude/keybindings.json` and are copied to `~/.claude/keybindings.json` by `tasks/install-claude.yml`. When suggesting or adding keybindings, check for conflicts in:
- `dots/tmux/tmux.conf` — prefix is `ctrl+space`; plain ctrl bindings: `ctrl+h`; most others are `ctrl+alt+*`
- `dots/config/sway/config` — `$mod = Mod1` (Alt); all sway bindings use `alt+*`. Keybinding reference table lives in `dots/config/sway/keybindings.md` — whenever a `bindsym` is added, changed, or removed in `dots/config/sway/config`, update that table in the same change.
- `dots/config/aerospace/aerospace.toml` — uses `alt+*` (workspaces/focus) and `ctrl+alt+*` (launchers)
- `dots/shell/bindkey.zsh` — zsh vi-mode bindings: `ctrl+k` (chord leader), `ctrl+n`/`ctrl+p` (history), `ctrl+e`/`ctrl+o` (git shortcuts); these only apply at the zsh prompt, not inside TUI apps

Available custom commands:
- `/cc` — conventional commit: diffs, stages session files, commits, and pushes
- `/role-update [name]` — checks local `bradfordwagner.ansible.role.*` repos for upstream version drift (table report), then on confirmation bumps + releases the ones that need it (branch → PR → CI → merge → tag → Galaxy publish → verify)

Custom keybindings (`dots/config/claude/keybindings.json`):
- `ctrl+y` — background current task/agent (return to fleet view)

