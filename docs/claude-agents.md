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
result" — which is exactly what smaller models hold worst. Hence `bw-release-planner` at
`sonnet` but `bw-release-releaser` at `opus`, despite sharing a domain and an estate: the
planner's failure mode is a bad document, the releaser's is a bad `terraform apply`. Rare
invocations on small inputs make the top tier cheap there anyway.

Available subagents:
- `bw-keybinding-auditor` (haiku) — read-only audit of a keybinding change across every layer that can
  claim a chord (GlazeWM's global hook, Windows Terminal, sway, aerospace, tmux, Claude Code,
  zsh), plus the doc-sync rules below. Knows the reserved chords (`alt+;`, `alt+ctrl+hjkl`,
  WT's `ctrl+v`→`null`) and normalizes the four different chord spellings before comparing.
  Also answers "is `<chord>` free?".
- `bw-release-planner` (sonnet) — plans a rollout across ArgoCD / Kargo / Terraform /
  Helm / Argo Workflows / `gh` and outputs a dependency **DAG** (Mermaid graph + ordered wave
  table with per-edge gates), not a checklist. Labels are wave-letter + step-number — `A1`,
  `A2` are wave A, `B1` is wave B — so a label says which wave it is in without a lookup, "run
  wave A" and "run A1, A2" are the same instruction, and a plan can be approved or amended by
  label. Nodes are declared in label order, which is also mermaid's layout order, so `A1` is
  top-left and the last step bottom-right. Clusters/apps get short aliases plus a legend
  rather than full identifiers. Knows the `tf.ci.cd` bootstrap ordering, that `sync-wave`
  annotations are authoritative, and which tools are actually installed (no
  kustomize/flux/tofu binary). Writes **two** files: `deploy-plan.html` for the human (Mermaid
  rendered client-side, Catppuccin Mocha) and `deploy-plan.md` for the releaser — a checkbox
  list of every label at the top, then a `## Context` section carrying each step's exact
  command, gate, dependencies, rollback and **Watch** — the `deploy-links.sh` invocation
  (`argocd vault`, `kargo ci prod`, `none`) the releaser turns into a link at run time. The split is so a human sees the whole rollout in
  one screen while the executing agent still has the detail. Read-only apart from those two
  files: runs `terraform plan` and `argocd app diff`, never `apply`/`sync`/`promote`.
  The mermaid source ends with a **release-status block** — four `classDef`s
  (done/active/failed/blocked) behind a marker comment, every label starting `pending` — which
  is the diagram's counterpart to the table's `data-status`. Validates with **both**
  `~/.claude/scripts/mermaid-validate.sh --render` (does it draw?) and
  `~/.claude/scripts/deploy-plan-lint.sh` (does it say what it means?) before reporting (see
  below). It is also the **only writer of those two files**, so it has a second mode: fed the
  releaser's status report after a wave, it moves each label in all three records — the `.md`
  checkbox, the table row's `data-status`, and the `class` lines under the diagram's status
  marker — then re-runs both validators, and amends the plan only where the report's
  Divergences say the plan itself was wrong.
- `bw-release-releaser` (opus) — executes an agreed plan, gated. Two things authorize it
  and nothing else: a plan (`deploy-plan.md`) and the user naming the labels to run. One wave
  per invocation, stops at every gate and returns rather than continuing; never runs a label
  it was not given; previews (`terraform plan` / `argocd app diff`) before every mutation and
  stops if reality diverges from the plan. Has **no write tools at all**: it closes with a
  status report that partitions *every* label in the plan into `done`/`active`/`failed`/
  `blocked`/`pending` plus a Divergences line, and hands that to the planner, which is what
  records it. **Opens by printing the links** for the steps it is
  about to run — ArgoCD app, Kargo stage, workflow, PR — before executing anything, since the
  window in which a link is useful is while the wave runs, not after it reports. A link that
  only exists once a step runs (the run a push triggered, a generated workflow name) is emitted
  the moment the identifier appears, mid-wave, rather than held for the report. Resolves them
  with `~/.claude/scripts/deploy-links.sh` rather than composing URLs, and reports an
  unresolvable base as the reason it gave.

The pair is deliberately split rather than one agent: a subagent's tool output is not shown
to you, so an agent that both planned and executed would collapse the human checkpoints that
wave gates exist to create. Splitting the *writing* the same way follows from it — the agent
that wants a step to have succeeded is the worst one to record whether it did, and one writer
means the checkbox, the table row and the painted node can never half-agree. So the loop is
planner → human → releaser → planner, and a wave is only recorded once its report comes back.
The cost is that the DAG repaints per wave rather than mid-flight; the live view during a wave
is the links the releaser prints, not the file.

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
- `bw-chart-author` (sonnet) — writes and refactors Helm charts in
  `github.bradfordwagner.k8s.deployments` with the environment layering built in: `values.yaml`
  is the complete working configuration sized for the largest environment, and every
  `values-${env}.yaml` carries only genuine deltas. An empty env file is a correct outcome, not
  an omission. It exists because values files rot toward duplication invisibly — a block copied
  into two env files reads fine the day it is written, and six months later one side has been
  tuned and the other has not. Helm deep-merges maps, so the copy was never needed; **lists**
  are the exception it has to check by hand, since an override that sets `syncOptions:` silently
  drops every entry it does not relist. Its hardest rule is that a values refactor must render
  **byte-identical** before and after — it snapshots `helm template` for every chart/env pair,
  diffs, and reports the diff rather than explaining it away. Also knows the local traps: that
  `charts/app-of-apps` per-app overrides replace wholesale rather than merging, that value files
  cannot carry per-cluster facts (Argo CD renders server-side, so the slug and `$USER` travel as
  helm parameters from `charts/root-app`), that a CRD over 262144 bytes needs `ServerSideApply`,
  and that a sync wave is a head start rather than a gate.
- `bw-claim-checker` (sonnet) — takes a draft commit message, PR body, review comment or
  summary and checks each factual assertion against the repo and the machine, reporting every
  claim verified / refuted / unverifiable with the command it used. Read-only: it never edits
  the text. Exists because a confident wrong claim is worse than no claim — it is believed and
  repeated — and history claims in particular are cheap to assert from memory and cheaper to
  refute with one `git log -S`.
- `bw-evidence-keeper` (sonnet) — diffs a session's `evidence.md` against what `evidence.sh`
  actually does and actually reports, and lists every place the two disagree. It flags, it
  never rewrites: deciding what the document should say is the author's judgment. Exists
  because evidence rots silently — a headline count drifts, a "not covered" item quietly
  becomes covered — and a stale evidence file is a confident wrong answer.
- `bw-session-state` (haiku) — reports what is actually true across every session on this
  machine right now: pool claims vs live k3d clusters vs session directories, which cluster
  carries the registry mirror config, each worktree's state, whether `~/.kube/config` still
  resolves, and the bead queue. Read-only. Exists because assembling it by hand is many
  mechanical commands whose results must be correlated, and the expensive failure is not
  noticing something — a peer session holding a slug, a kubeconfig symlink left dangling.

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

#### `mermaid-validate.sh`

`dots/config/claude/scripts/mermaid-validate.sh` checks the Mermaid diagrams in an HTML file —
or a bare diagram on stdin with `-`. It exists because a `<pre class="mermaid">` block only
renders when a browser runs it, so the planner cannot see its own mistakes: a bad diagram
reaches the user as an empty box. Its prompt requires a clean run before reporting.

Two modes, catching different things, and the parse alone is **not** enough:

- **parse** (default, `mermaid-validate.mjs`, ~1s) — the grammar. Catches unquoted labels,
  reserved-word node ids, empty edge labels.
- **`--render`** (`mermaid-render.mjs`, ~2s) — a real headless Chromium opening the file over
  `file://`. Catches what the grammar cannot: a mermaid `<script>` that 404s or never loads, a
  **duplicate node id** (parses clean, renders as mermaid's error card), an unknown shape, a
  zero-height diagram. `--offline` is the same with every non-`file://` request aborted, for
  when a plan must work without a network.

`file://` is the point — it is how the plan is opened and it is *stricter* than `http://`: a
`<script type="module">` importing a sibling file is blocked as cross-origin, so a CDN import
is the only workable pattern for a one-file page. Note the exact URL: jsdelivr serves
`mermaid.esm.min.mjs`; `mermaid.esm.min.js` is a 404.

Three details worth keeping:

- Parse mode reads the file the way a browser does — jsdom parses the HTML, the diagram comes
  from `innerHTML`, then through mermaid's own `entityDecode` + dedent, exactly as
  `mermaid.run()` does. Skipping that flags every diagram containing `-->`, since `innerHTML`
  re-serialises `>` as `&gt;`.
- Render mode waits for `aria-roledescription` on the `<svg>`, not for `data-processed` or for
  the element to exist. mermaid sets both of those *before* the diagram is drawn, so either
  one reports a perfectly good diagram as an error card.
- mermaid's failure mode is a rendered error card, not an exception — so a picture of a
  failure is detected as one (`aria-roledescription="error"`, a missing role, or `.error-icon`).

mermaid ships browser-only and its DOMPurify reads `window` at import time, hence jsdom
(~180M); `--render` additionally pulls `playwright-core` and a headless Chromium (~275M —
`chromium-headless-shell`, not full Chromium, which is 135M smaller and enough). Both install
on demand into `${XDG_CACHE_HOME:-~/.cache}/mermaid-validate` (override with
`MERMAID_VALIDATE_CACHE`), the browser only if `--render` is actually used. Nothing is
vendored and nothing is in the Brewfile: it is a dev aid for one agent. Homebrew's
`mermaid-cli` was the tempting shortcut but is strictly worse here — it renders through its
own harness rather than through the page, so it cannot see a broken `<script>` tag at all.
Exit 2 is the tool failing to run (no node/npm, unreadable file, browser download failed),
distinct from exit 1 for a bad diagram.

#### `deploy-plan-lint.sh`

The other half of the planner's validation, and it exists because `mermaid-validate.sh` answers
only "does this draw?". A diagram can render beautifully and still be wrong. The planner shipped
a plan whose "Wave A" held `A1 B1 N1` and whose "Wave B" held `C1 D1 P1 E1 O1` — every wave's
steps lettered as though they were waves themselves, which breaks the one property the label
scheme exists for: that "run wave A" and "run A1, A2" are the same instruction.

The failure is structural, not careless. Steps get enumerated and lettered as they are
discovered, dependencies get worked out, subgraphs get drawn — and the letters are never
revisited. Every label being a `1` is the tell. So the prompt now orders it (group into waves,
*then* label, as separate numbered steps) and this script enforces it: every node in
`subgraph wX` labelled `X<n>`, numbered from 1 with no gaps, waves in alphabetical order.

It also cross-checks the three artifacts that must agree — the diagram's labels, the
`id="step-<LABEL>"` rows and their `data-status` handles, and the Markdown's checkboxes,
`<!-- wave X -->` groups and `### <LABEL>` context sections — same set, same order.

And it validates the **release-status block** the releaser rewrites, which is where the
subtlest failure lives: **mermaid ignores a `class` line naming a node that does not exist.**
No error, no error card — the node simply never gets painted. So a mistyped label renders as a
flawless diagram that quietly under-reports progress, and `--render` passes it. The lint
catches that, a label missing from the block entirely, a state with no `classDef`, and a node
claimed by two states. Decorative classes are left alone: a node may hold both `gate` and
`done`, since the status `classDef` is defined last and wins the cascade — only two *release
states* on one node is a conflict.

It also checks the planner's **Watch** lines, where the trap is the opposite of a typo: a
plausible one. A `Watch` holding a full URL passes every other check and keeps opening
whatever cluster happened to be current when the plan was written — so the lint requires a
`deploy-links.sh` invocation (`argocd vault`, `kargo ci prod`, `none`) and rejects anything
with a scheme in it, and requires the `after <verb>` form to name a verb that can actually be
deferred. A plan with no `Watch` lines at all is a note, not a failure: plans predating this
still work, and the releaser falls back to deriving the target from the step's command.

Pure python3/bash, no dependencies, nothing to install. Same exit convention as its sibling: 0
clean, 1 a bad plan, 2 the tool could not run.

#### `deploy-links.sh`

`dots/config/claude/scripts/deploy-links.sh` turns a thing a step touches into the URL for it:
`deploy-links.sh argocd <app> [<ns>]`, `kargo <project> [<stage>]`, `workflow <ns> <name>`,
`gh-pr <n>`, `gh-run <id>`, `gh-run-for <sha>`, `gh-actions`, `promotion <proj> <id>`,
`vault <mount> <path>`, and `bases` to see which of those can resolve at all right now. One URL
per call on stdout, diagnostics on stderr.

`bw-release-releaser` runs it before a wave, not after, because the window in which a
deployment link is useful — an app going `Progressing`, a workflow's pods starting, a PR's
checks turning over — is open while the wave runs and shut by the time the report lands.

The same logic, harder, for links that **cannot** exist up front: a `git push` triggers a run
whose id GitHub assigns, `argo submit` generates a workflow name, `kargo promote` mints an id.
Those are the most valuable links in a release — something is running *right now* — and the
easiest to lose, since the natural place to put them is the end-of-wave report, by which time
the build is over. So the releaser treats a new identifier as an interrupt: capture it from the
command's own output (`argo submit -o name`, `git rev-parse HEAD`, `kargo promote -o json`),
resolve, print immediately. Never `--wait`/`--log` to obtain it — those block until the thing
finishes, which is the whole problem. `gh-run-for <sha>` covers the awkward one: a run does not
register the instant a push lands, so it polls ~30s (`DEPLOY_LINKS_WAIT`) and, failing, says
so — "no run for that sha" usually means a branch or path filter did not match, worth knowing
early. Plans mark these steps `Watch: after gh-run-for` / `after workflow <ns>` / `after
promotion <proj>` — the verb without the id the planner cannot know.

Why a script rather than letting the agent compose the URL: a wrong link here is worse than no
link, and it is invisible. A URL that 404s wastes a click, but one pointing at the *right app
in the wrong cluster* renders a real page showing real state, and the user has no way to tell.
So every base comes from what the machine is already pointed at — `argocd context`,
`kargo config view` (`apiAddress`), `$ARGO_SERVER`, `$VAULT_ADDR`, `gh repo view` — the same
sources the commands themselves use, which is exactly what keeps the link and the action
aimed at one place. An unresolvable base exits 1 with the reason ("no current argocd
context"), and the agent is told to report that line rather than substitute a guess: a named
gap usually means a login the user wants to know is missing.

The same reasoning puts **Watch** in the plan as `argocd vault` rather than a URL. The planner
had the manifests open and knows the identifier; it does *not* know which context the release
will run under days later, so resolution belongs at run time. The lint enforces that split.

Two estate-specific notes. Argo Workflows has no config file to read — the CLI takes its
server from the environment — so `$ARGO_SERVER` is the only honest source, and with it unset
(the usual state here, since it is reached by port-forward) the subcommand reports that rather
than guessing a localhost port. And `:443` is stripped from bases, since argocd contexts carry
it and it only makes the URL uglier. Each resolver has a
`DEPLOY_LINKS_{ARGOCD,KARGO,ARGO,VAULT}_URL` override for when the CLI points at an in-cluster
service address a browser cannot follow.

Pure bash, no dependencies beyond the CLIs it reads. Same exit convention as its siblings, with
the middle one meaning something slightly different: 0 a URL was printed, 1 the base could not
be resolved, 2 the tool could not run (unknown subcommand, missing argument, absent CLI).

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

