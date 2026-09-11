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
result" — which is exactly what smaller models hold worst. Hence `bw-deployment-planner` at
`sonnet` but `bw-deployment-releaser` at `opus`, despite sharing a domain and an estate: the
planner's failure mode is a bad document, the releaser's is a bad `terraform apply`. Rare
invocations on small inputs make the top tier cheap there anyway.

Available subagents:
- `bw-keybinding-auditor` (haiku) — read-only audit of a keybinding change across every layer that can
  claim a chord (GlazeWM's global hook, Windows Terminal, sway, aerospace, tmux, Claude Code,
  zsh), plus the doc-sync rules below. Knows the reserved chords (`alt+;`, `alt+ctrl+hjkl`,
  WT's `ctrl+v`→`null`) and normalizes the four different chord spellings before comparing.
  Also answers "is `<chord>` free?".
- `bw-deployment-planner` (sonnet) — plans a rollout across ArgoCD / Kargo / Terraform /
  Helm / Argo Workflows / `gh` and outputs a dependency **DAG** (Mermaid graph + ordered wave
  table with per-edge gates), not a checklist. Every step gets a letter label (A, B, C…) so a
  plan can be approved or amended by label, and clusters/apps get short aliases plus a legend
  rather than full identifiers. Knows the `tf.ci.cd` bootstrap ordering, that `sync-wave`
  annotations are authoritative, and which tools are actually installed (no
  kustomize/flux/tofu binary). Outputs a self-contained HTML file (Mermaid rendered
  client-side, Catppuccin Mocha styling), not Markdown. Read-only apart from writing
  `deploy-plan.html`: runs `terraform plan` and `argocd app diff`, never
  `apply`/`sync`/`promote`. Parse-checks its own diagram with
  `dots/shell_scripts/mermaid-validate.sh` before reporting (see below).
- `bw-deployment-releaser` (opus) — executes an agreed plan, gated. Two things authorize it
  and nothing else: a plan (`deploy-plan.html`) and the user naming the labels to run. One wave
  per invocation, stops at every gate and returns rather than continuing; never runs a label
  it was not given; previews (`terraform plan` / `argocd app diff`) before every mutation and
  stops if reality diverges from the plan. Ticks off completed labels so progress survives
  across invocations.

The pair is deliberately split rather than one agent: a subagent's tool output is not shown
to you, so an agent that both planned and executed would collapse the human checkpoints that
wave gates exist to create.

#### `mermaid-validate.sh`

`dots/shell_scripts/mermaid-validate.sh` (plus its `.mjs` payload) parse-checks the Mermaid
diagrams in an HTML file — or a bare diagram on stdin with `-` — and exits non-zero with the
parse error and a numbered source listing. It exists because a `<pre class="mermaid">` block
only renders when a browser runs it, so the planner cannot see its own syntax errors: a bad
diagram reaches the user as an empty box. Its prompt requires a clean run before reporting.
Useful by hand for any Mermaid anywhere in the repo.

The file is read the way a browser reads it — jsdom parses the HTML and the diagram is taken
from `innerHTML`, then run through mermaid's own `entityDecode` + dedent, exactly as
`mermaid.run()` does. Skipping that would flag every diagram with a `-->` in it, since
`innerHTML` re-serialises `>` as `&gt;`.

mermaid ships browser-only and its DOMPurify reads `window` at import time, so this needs
jsdom — ~180M of `node_modules`. That is installed on first run into
`${XDG_CACHE_HOME:-~/.cache}/mermaid-validate` (override with `MERMAID_VALIDATE_CACHE`), not
vendored and not in the Brewfile: it is a dev aid for one agent, and Homebrew's `mermaid-cli`
would be the heavier answer (it pulls a headless Chromium to *render*, when only parsing is
needed). First run takes a few seconds; later runs ~0.5s. Exit 2 is the tool failing to run
(no node/npm, unreadable file), distinct from exit 1 for a malformed diagram.

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
