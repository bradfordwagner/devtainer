# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bradford's personal dotfiles ("devtainer"). Ansible is the deployment engine; `go-task` (Taskfile.yml) is the task runner. Running the playbook symlinks configs, renders Jinja2 templates, and installs packages — it does not copy files except for `install-dotfiles.yml` (which syncs the repo itself when running remotely).

## Detail docs

This file is the map; the depth lives beside the thing it describes. Keep it that way — it has
a 40k-char budget and blew through it once already.

| Doc | Covers |
|---|---|
| `docs/claude-agents.md` | Every subagent and agent script, with rationale |
| `docs/windows-wsl.md` | GlazeWM / Zebar / Windows Terminal layout and keybindings |
| `docs/sessions.md` | Multi-repo worktree sessions, in full |
| `dots/config/glazewm/keybindings.md` | GlazeWM binding table + keyboard maps |
| `dots/config/sway/keybindings.md` | sway binding table |
| `dots/config/zebar/README.md` | Vendored Zebar pack, theming |
| `wsl.md` / `coder.md` | Host setup guides |

Agent scripts in `dots/config/claude/scripts/` carry their full reasoning in their own header
comments — read those before the docs.

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

`dots/config/claude/` holds slash commands, subagents, agent scripts and keybindings, all
**copied** (not symlinked) into `~/.claude/` by `tasks/install-claude.yml`. Re-run `task bb`
to deploy any change there.

Two rules that are easy to get wrong, so they live here rather than in the detail doc:

- Name subagents with a `bw-` prefix. `~/.claude/agents/` is a flat namespace shared with
  plugins and built-ins, and the prefix is what marks an agent as ours.
- Pin `model:` explicitly; never `inherit`. `settings.json` sets the session model to
  `opus[1m]`, so `inherit` bills every subagent run at the top tier with a 1M window. Start at
  `haiku` and escalate on evidence, sorting by **blast radius** rather than domain: an agent
  whose bad output you read before acting on it can stay low, while one that mutates real
  infrastructure cannot, since its hardest instructions are *restraints* and those are what
  smaller models hold worst.

Agents (`dots/config/claude/agents/`): `bw-accountant`, `bw-k8s-author`. Commands
(`dots/config/claude/commands/`): `/cc`, `/role-update`.

**See `docs/claude-agents.md`** for what each agent does and why, and the agent scripts
(`session-usage.sh`) — which also carries its full rationale in its own header comment.

When adding or changing a keybinding anywhere, check for conflicts across every layer that can
claim a chord:
- `dots/tmux/tmux.conf` — prefix is `ctrl+space`; plain ctrl bindings: `ctrl+h`; most others are `ctrl+alt+*`
- `dots/config/sway/config` — `$mod = Mod1` (Alt); all sway bindings use `alt+*`. Whenever a `bindsym` is added, changed, or removed, update the reference table in `dots/config/sway/keybindings.md` in the same change.
- `dots/config/aerospace/aerospace.toml` — `alt+*` (workspaces/focus), `ctrl+alt+*` (launchers)
- `dots/shell/bindkey.zsh` — zsh vi-mode: `ctrl+k` (chord leader), `ctrl+n`/`ctrl+p` (history), `ctrl+e`/`ctrl+o` (git); prompt only, not inside TUI apps
- `dots/config/glazewm/config.yaml` — global hook, so it takes the chord from everything else; see `docs/windows-wsl.md`
- `dots/config/claude/keybindings.json` — `ctrl+y` backgrounds the current task/agent

#### Image paste on WSL (`dots/shell_scripts/wsl-shims/`)

`ctrl+v` to paste a screenshot into Claude Code is broken on WSL by two separate interceptors.
The **keys**: Claude binds image-paste to `alt+v` and `ctrl+v`, which Windows Terminal and
GlazeWM were both eating — WT's `ctrl+v` is now `null` (text paste moved to `ctrl+shift+v`) and
must stay unbound. The **clipboard**: WSLg offers a Windows-copied image only as 32bpp
`BI_BITFIELDS` `image/bmp`, which libvips cannot load, and `wl-paste` exits 0 on it — short-
circuiting Claude's `||` chain before the PowerShell branch that actually works.
`dots/shell_scripts/wsl-shims/wl-paste` fails `image/*` reads under WSL only, so the chain
falls through; `dots/shell/common.linux.zsh` prepends the shim dir to `PATH`. Full reasoning is
in that shim's header comment, and the full diagnosis is in `docs/windows-wsl.md`. Verify with
`wsl-shims/test-clipboard.sh` in a **new** shell (Claude inherits `PATH` at launch). Still
unfixed upstream as of 2.1.267.

### GlazeWM + Zebar + Windows Terminal (WSL only)

Windows-side apps configured from WSL by `tasks/windows-wsl.yml` (runs only when
`ansible_facts.kernel` matches `microsoft`). GlazeWM and Zebar configs are **copied** into
`%USERPROFILE%\.glzr\` — a symlink made from WSL on DrvFs is a WSL-style symlink Windows apps
cannot follow. Windows Terminal is **merged** rather than copied, since `profiles.list` and
`defaultProfile` are per-machine GUIDs: `dots/config/windows-terminal/merge-settings.py` folds
`settings.managed.json` in and leaves every key absent from it as WT wrote it.

Two constraints worth knowing before touching a binding:

- WT's `ctrl+v` must stay bound to `null` or Claude Code's image paste breaks (above).
- GlazeWM's keyboard hook is **global**, so a binding here is taken away from tmux, nvim and
  sway-over-RDP. `alt+;` and `alt+ctrl+hjkl` are reserved for tmux.

Both apps are themed **Catppuccin Mocha**, matching `ghostty_theme` in `variables.yml` —
retheme them together. Reload after `task bb`: GlazeWM via tray icon or `alt+shift+r`; Zebar
needs a process restart.

Any add/change/removal of a binding or workspace in `dots/config/glazewm/config.yaml` must
update **both** reference files in the same change — easy to miss the second when the change
looks like a one-line config edit:

- `dots/config/glazewm/keybindings.md` — markdown table + ASCII keyboard maps
- `dots/config/glazewm/keybindings.html` — rendered keycap version, **published as an
  Artifact**; redeploy to the same URL
  (`https://claude.ai/code/artifact/b019cd7d-7a3f-4745-80ef-097fb739e209`) rather than
  publishing a new one

**See `docs/windows-wsl.md`** for the full layout table, the workspace grid, the
`stack.cmd` accordion workaround, and the Zebar vendored-pack details (also
`dots/config/zebar/README.md`).

### sessions (multi-repo worktrees)

`dots/shell/sessions.sh` defines the `sessions` function (`sessions new|add|delete`, or fzf
picks the verb). A *session* is one branch name spanning N repos: a `git worktree` of each
under `~/sessions/${name}/${repo}`, `sessions.md` copied in as the session's `CLAUDE.md`, a
tmux window, and one `bd init` beads tracker at the session root so every repo shares an issue
graph. Nothing touches the original checkouts except advancing `origin/*`.

`delete` never deletes branches — they may hold the only copy of unpushed work — and prompts
when a worktree is dirty or beads are open.

Overridable: `SESSIONS_ROOT`, `SESSIONS_TMUX`, `SESSIONS_TEMPLATE`, `SESSIONS_SCAN_DEPTH`.

**See `docs/sessions.md`** for repo-name resolution, the `--no-track` branch base and why its
fetch is load-bearing, the beads flags, and why the session root is deliberately not a git repo.

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
