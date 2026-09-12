# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bradford's personal dotfiles ("devtainer"). Ansible is the deployment engine; `go-task` (Taskfile.yml) is the task runner. Running the playbook symlinks configs, renders Jinja2 templates, and installs packages — it does not copy files except for `install-dotfiles.yml` (which syncs the repo itself when running remotely).

## Common commands

```bash
task              # full install: brew + git clones + vim/shell packages
task bb           # bare-bones: links + templates only, no package installs
task git          # git clones only: syncs all workspace repos (bradfordwagner + github modules)
task git_bw       # git clones only: bradfordwagner repos (alias: gb)
task git_os       # git clones only: third-party github repos (alias: go)
task lbc          # check linux brew bundle
task lbi          # install linux brew bundle
task sudoer       # run sudoer playbook (asks for become password)
task ilv          # init variables.local.yml from variables.yml (skips if exists)
```

To run just a specific Ansible task file directly:
```bash
ansible-playbook -i localhost, -c local playbook.yml --tags <tag>
# or target a single include manually:
ansible-playbook -i localhost, -c local playbook.yml -e 'install_vim_shell_packages=false brew_install=false git_clone=false'
```

The `key=value` form of `-e` passes **strings**, not booleans — ansible-core 2.21 rejects a
bare string in a `when:`, so every conditional on one of those flags carries `| bool`. The
Taskfile is unaffected either way: it uses the YAML-dict form (`-e '{git_clone: true}'`),
which parses as a real boolean. Keep `| bool` on any new `when:` that tests a CLI-overridable
flag.

Syntax check an Ansible task file:
```bash
ansible-playbook --syntax-check -i localhost, -c local playbook.yml
```

## Architecture

### Deployment flow

```
Taskfile.yml → ansible-galaxy (requirements.yml) → playbook.yml
                                                        ├── tasks/packages-arch.yml           (Arch pacman)
                                                        ├── tasks/packages-osx.yml            (Homebrew)
                                                        ├── tasks/install-dotfiles.yml        (rsync repo, remote only)
                                                        ├── tasks/jinga-templates.yml         (render .gitconfig, .zshenv, MCP configs)
                                                        ├── tasks/link-shell.yml              (symlinks dots/ → ~/.config/, ~/.zshrc, etc.)
                                                        ├── tasks/install-claude.yml          (copy dots/config/claude/{commands,agents,hooks}/ → ~/.claude/)
                                                        ├── tasks/windows-wsl.yml             (WSL only: glazewm+zebar+terminal configs → %USERPROFILE%)
                                                        ├── tasks/install-windsurf-workflows.yml
                                                        ├── tasks/install-shell-packages.yml
                                                        └── [when git_clone=true]
                                                            ├── tasks/git-modules-bradfordwagner.yml  (clone ~/workspace/github/bradfordwagner/*)  [git_clone_bw]
                                                            └── tasks/git-modules-github.yml                                                       [git_clone_os]
```

### Directory layout

- `dots/config/` — configs symlinked to `~/.config/<name>` (nvim, sway, waybar, tmux, alacritty, ghostty, etc.). Changes here are live immediately — no need to run `task bb`.
- `dots/shell/` — zsh files sourced via `~/.zshenv` → `env.sh.j2`. Load order: `palette.zsh` → `common.zsh` → `local.zsh` → `alias.zsh` → `git.zsh` → others (incl. `sessions.sh`). Adding a file here means adding a `source` line to `templates/env.sh.j2` and re-running `task bb`.
- `dots/tmux/` — tmux.conf + tmuxinator sessions
- `templates/` — Jinja2 templates rendered by `tasks/jinga-templates.yml` into home directory files
- `tasks/` — individual Ansible task files included from `playbook.yml`

### Variables

- `variables.yml` — defaults (committed, safe to read). Covers alacritty/ghostty theme/font, MCP server paths/URLs, `user_name`.
- `variables.local.yml` — machine-local overrides (gitignored). Created via `task ilv`. Always takes precedence; loaded with `ignore_errors: yes` if missing.

The git-clone block is gated by `git_clone`, then narrowed per source by `git_clone_bw`
(bradfordwagner repos) and `git_clone_os` (third-party github repos). Both default to `true`,
so `-e git_clone=true` on its own still clones everything; `task git_bw` / `task git_os` flip
one of them off.

### Templates rendered at playbook time

| Template | Destination |
|---|---|
| `templates/env.sh.j2` | `~/.zshenv` (ANSIBLE MANAGED BLOCK) |
| `templates/gitconfig.j2` | `~/.gitconfig` (ANSIBLE MANAGED BLOCK) |
| `templates/cursor.mcp.json.j2` | `~/.cursor/mcp.json` |
| `templates/alacritty.toml.j2` | via alacritty task |
| `templates/ghostty.j2` | via ghostty task |
| `templates/k9s.yaml.j2` | `~/Library/Application Support/k9s/config.yaml` |
| `templates/xsession.j2` | `~/.xsession` (Linux only, launches sway directly for xrdp) |

### Claude Code integration

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

- `bw-accountant` (sonnet) — maintains `ledger.md`: what sessions cost, which models spent
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

#### Image paste on WSL (`dots/shell_scripts/wsl-shims/`)

`ctrl+v` to paste a screenshot into Claude Code is broken on WSL by two separate
interceptors, both fixed here.

**The keys.** Claude binds image-paste to *both* `alt+v` and `ctrl+v` on WSL
(`Pev = Dev ? "alt+v" : "ctrl+v"`, plus an extra `{"ctrl+v": "chat:imagePaste"}` when the
platform is `wsl`). Windows Terminal had `Terminal.PasteFromClipboard` on `ctrl+v`, and
GlazeWM has `focus --workspace v` on `alt+v` — so neither key reached Claude. WT's `ctrl+v`
is now unbound (text paste moved to `ctrl+shift+v`); `alt+v` stays with GlazeWM. That WT
setting is managed by `tasks/windows-wsl.yml` (see the Windows-side apps section for how),
so it survives a rebuild.

**The clipboard.** Claude's WSL `saveImage` is a `||` chain:

    xclip png || wl-paste png || xclip bmp || wl-paste bmp || powershell.exe -> base64 PNG

WSLg advertises a Windows-copied image to Wayland *only* as `image/bmp`, and the BMP is
32bpp `BI_BITFIELDS` (compression 3). libvips ships no BMP loader, so Claude's
`sharp(buf).png()` throws and the catch reports the misleading "No image found in
clipboard". The PowerShell branch returns a real PNG and works — but `wl-paste --type
image/bmp` exits 0 first and short-circuits the `||`, so it is never reached. Machines
without `wl-clipboard` installed therefore work fine; this one has it because it came in
with the sway stack (`apt install sway ... wl-clipboard ...`).

`dots/shell_scripts/wsl-shims/wl-paste` fails `image/*` reads — and only those, and only
under WSL — so the chain falls through to PowerShell. Text reads, `--list-types` and every
other flag `exec` the real `/usr/bin/wl-paste`, and `wl-copy` is untouched, which keeps the
`pbcopy`/`pbpaste` aliases (`dots/shell/alias.zsh`) and `dots/shell_scripts/screenshot.sh`
working. `dots/shell/common.linux.zsh` prepends the shim dir to `PATH`, gated on
`$WSL_DISTRO_NAME`/`$WSL_INTEROP`, so it is inert on macOS and the Coder pod. Deleting the
shim reverts everything.

Removing the `wl-clipboard` package would also fix Claude — nothing depends on it — but it
would break `screenshot.sh` and leave no `pbpaste` (no `xsel` installed), hence the shim.

Verify with `dots/shell_scripts/wsl-shims/test-clipboard.sh`: copy a screenshot, run it in a
**new** shell (Claude inherits `PATH` at launch, so a running session keeps the old one).
It checks the shim resolves, the image read is refused, Claude's real chain yields PNG, and
the text roundtrip still works — note it consumes the clipboard image in the last step.

Still unfixed upstream as of 2.1.267 (checked against 2.1.236): same chain, same
unconditional `sharp()` on BMP bytes.

### GlazeWM + Zebar + Windows Terminal (WSL only)

Windows-side apps configured from WSL. `tasks/windows-wsl.yml` runs only when
`ansible_facts.kernel` matches `microsoft`, resolves `%USERPROFILE%` via `cmd.exe`/`wslpath`,
and **copies** configs into `%USERPROFILE%\.glzr\`. They must be copies — a symlink created
from WSL on DrvFs (`/mnt/c`) is a WSL-style symlink that Windows apps can't follow. The task
sets no `mode:` because DrvFs ignores unix permissions and would otherwise report `changed`
every run.

| repo source | destination |
|---|---|
| `dots/config/glazewm/config.yaml` | `.glzr\glazewm\config.yaml` |
| `dots/config/glazewm/stack.cmd` | `.glzr\glazewm\stack.cmd` |
| `dots/config/zebar/bw-starter/` | `.glzr\zebar\bw-starter\` |
| `dots/config/zebar/settings.json` | `.glzr\zebar\settings.json` |

The same task also manages **Windows Terminal**, but by *merge* rather than copy —
`dots/config/windows-terminal/merge-settings.py` folds
`settings.managed.json` into
`%LOCALAPPDATA%\Packages\{{ win_terminal_package }}\LocalState\settings.json`. Copying
is wrong there for two reasons: `profiles.list` and `defaultProfile` are per-machine GUIDs
that WT mints at install (shipping this box's would point a rebuilt machine's default at a
profile that does not exist), and WT rewrites the file itself as distros appear or settings
change in the UI. So the repo owns a subset — `keybindings`, `actions`, `schemes`, `themes`,
`profiles.defaults`, and the top-level toggles — and every key absent from
`settings.managed.json` is left as WT wrote it. The script prints `changed`/`ok` for
`changed_when` and backs up to `settings.json.bak` before writing. `win_terminal_package`
(`variables.yml`) is the MSIX dir name; the preview build uses a different one.

The keybinding that matters is `ctrl+v` bound to `null`: it must stay unbound for Claude
Code's image paste to work, since WT would otherwise consume the key for text paste. Text
paste lives on `ctrl+shift+v`. See the WSL image-paste section above.

GlazeWM's local deltas from the upstream sample config: gaps are `4px`, except the top outer
gap at `32px` — Zebar's 28px bar plus the same 4px gap, so windows clear the bar without an
oversized top margin — and `alt+enter` runs `shell-exec wt -f` rather than upstream's
`shell-exec cmd`, so it opens Windows Terminal in focus mode honouring its own
`defaultProfile` (Ubuntu/WSL) instead of forcing a shell.

The keybindings are also heavily reworked from upstream: the left-hand key block
(`qwert`/`asdfg`/`zxcvb`) is 15 letter-named workspaces on `alt+<key>` (focus) and
`alt+shift+<key>` (move + follow), matching `dots/config/aerospace/aerospace.toml` where
every letter is a workspace. That displaced 15 commands onto punctuation (`alt+/` tiling
direction, `alt+,` tiling, `alt+.` fullscreen, `alt+[`/`alt+]` workspace nav, `alt+Escape`
recent) plus a `service` binding mode on `alt+shift+'` holding
exit/reload/redraw/pause/close and the move-workspace-to-monitor directions — the aerospace
`[mode.service.binding]` idiom.

Binding modes are **exclusive, not additive** — while one is active every other binding is
dead, the workspace grid included. That rules them out for anything you stay in, which is
why the stand-in for aerospace's accordion layout is a script instead.
`dots/config/glazewm/stack.cmd` wraps the `alt+hjkl` / `alt+shift+hjkl` bindings and
branches on whether the focused window is fullscreen: if it is, un-fullscreen → step →
re-fullscreen walks the workspace one full-size window at a time (a fullscreen window keeps
its slot in the tree); if not, it is a plain pass-through. So "this workspace is stacked"
*is* "its focused window is fullscreen", `alt+.` is the layout toggle, and there is no state
to get out of sync. Costs ~70ms unstacked / ~110ms stacked per keypress; `shell-exec
--hide-window` stops the `cmd` console flashing. Neither `focus --direction` alone nor
`wm-cycle-focus` traverses fullscreen windows, and `resize --width` is relative rather than
absolute, so the neighbour-peek half of a real accordion is unreachable — the full reasoning
is in that script's header and `dots/config/glazewm/keybindings.md`.

GlazeWM's keyboard hook is global, so a binding here is taken away from tmux/nvim/WSL and
from sway over RDP; `alt+;` and `alt+ctrl+hjkl` are reserved for
tmux (`resize-pane -Z`, `select-pane`), which is why the modes sit on the quote key. Check
`dots/tmux/tmux.conf` root-table (`bind -n`) chords before adding a GlazeWM binding. The
reference table and keyboard maps live in **two** files that must both be updated in the
same change as any add/change/removal of a binding or workspace in
`dots/config/glazewm/config.yaml` (same rule as `dots/config/sway/keybindings.md`):

- `dots/config/glazewm/keybindings.md` — the markdown table + ASCII keyboard maps
- `dots/config/glazewm/keybindings.html` — the rendered keycap version; it is **published as
  an Artifact**, so after editing it redeploy to the same URL with the `Artifact` tool
  (`url: https://claude.ai/code/artifact/b019cd7d-7a3f-4745-80ef-097fb739e209`) rather than
  publishing a new one

Easy to miss the `.html` when the change looks like a one-line config edit — check for both.

Zebar runs a **vendored** copy of the `glzr-io.starter` marketplace pack (upstream's documented
way to edit a marketplace widget without pack updates overwriting it); the pack id is the
directory name, `bw-starter`. Its changes: weather in fahrenheit, a Catppuccin Mocha theme,
CPU/memory shown as used/total plus percent (CPU first), network down/up throughput in
bytes-per-second SI units (`1.4 MBps`) in place of upstream's wifi ssid/signal readout, and
battery time remaining.
Details, the bar-height/`outer_gap.top` coupling, and how to retheme are in
`dots/config/zebar/README.md`.

Both apps are themed **Catppuccin Mocha**, matching `ghostty_theme` in `variables.yml` — the
bar in `dots/config/zebar/bw-starter/styles.css`, GlazeWM's window borders (mauve focused,
surface0 unfocused) in `dots/config/glazewm/config.yaml`. Retheme both together.

Reload after `task bb`: GlazeWM via tray icon or `alt+shift+r`; Zebar needs a process restart
(it only reads `settings.json` and packs at startup).

### sessions (multi-repo worktrees)

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

### MCP servers

Configured via `templates/cursor.mcp.json.j2` (rendered to `~/.cursor/mcp.json`):
- `argocd-mcp` — ArgoCD MCP server (pnpm/tsx), path set via `argocd_mcp_dir`
- `bw-mcp` — Bradford's custom Go MCP server, path set via `bradfordwagner_mcp_dir`

Token/URL config goes in `variables.local.yml`.

### Setup docs: `wsl.md` vs `coder.md`

Two hand-run setup guides. They share the same desktop stack (xrdp → Xorg → sway via
`~/.xsession`, tmux/nvim conflict notes) but target different hosts — keep platform-specific
steps in the right file and don't cross-contaminate.

- **`wsl.md`** — WSL2 on Windows. Has systemd (`systemd=true` in `/etc/wsl.conf`), so
  `systemctl enable --now`, snaps, and the default Homebrew prefix (`/home/linuxbrew`) all work
  normally. The whole filesystem is persistent.
- **`coder.md`** — bare Coder Kubernetes pod. **No systemd** (use `service`, not `systemctl`;
  no snaps → firefox comes from Mozilla's APT repo, not the Ubuntu stub), no window manager,
  and the writable layer (`/`) is **wiped on rebuild** while only `~/` (`/home/coder`, a PV)
  persists. Hence the `XDG_RUNTIME_DIR` guard in `templates/xsession.j2`, the `sesman.ini`
  socket-group fix, and the Homebrew symlink (`~/linuxbrew` ← `/home/linuxbrew/.linuxbrew`) so
  bottles keep working while the store lives on the PV. Anything touching `/` must be re-run
  per rebuild or baked into the base image.

When editing: a change to the shared stack (e.g. the `.xsession`/sway launch) usually belongs
in `templates/xsession.j2` and should be reflected in **both** docs; a systemd/persistence/snap
detail belongs in exactly one.
