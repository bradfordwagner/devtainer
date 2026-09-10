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
                                                        ├── tasks/install-claude.yml          (copy dots/config/claude/commands/ → ~/.claude/commands/)
                                                        ├── tasks/windows-wsl.yml             (WSL only: copy glazewm+zebar configs → %USERPROFILE%)
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

### GlazeWM + Zebar (WSL only)

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
not inherit the base as its upstream. `delete` unregisters the worktrees from their *original*
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
this; and a subshell `cd` rather than `bd -C`, which does not pick up the repo's `beads.role`
(GH#2950). No bd on PATH means both helpers no-op.

`bd init` also runs `git init` at the session root for its hooks — hence `delete`'s
`find -mindepth 2`, without which that `.git` is swept in as a worktree of nothing and makes
every teardown claim unsaved work. Since `rm -rf` takes the tracker with the session, `delete`
now warns on open beads the same way it warns on dirty worktrees, and one confirmation covers
both. Counts are grepped down to a bare integer because bd interleaves throttled tips with its
output.

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
