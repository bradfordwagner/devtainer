# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bradford's personal dotfiles ("devtainer"). Ansible is the deployment engine; `go-task` (Taskfile.yml) is the task runner. Running the playbook symlinks configs, renders Jinja2 templates, and installs packages — it does not copy files except `install-dotfiles.yml` (syncs the repo itself when running remotely) and the copy-based tasks noted below.

## Detail docs

This file is the map; the depth lives beside the thing it describes. Keep it that way — it has
a 40k-char budget and blew through it once already.

| Doc | Covers |
|---|---|
| `docs/claude-agents.md` | Every subagent and agent script, with rationale |
| `docs/windows-wsl.md` | GlazeWM / Zebar / Windows Terminal layout, keybindings, WSL image-paste diagnosis |
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
task git          # git clones only: all workspace repos (bradfordwagner + github modules)
task git_bw       # bradfordwagner repos only (alias: gb)
task git_os       # third-party github repos only (alias: go)
task lbc / lbi    # check / install linux brew bundle
task sudoer       # run sudoer playbook (asks for become password)
task ilv          # init variables.local.yml from variables.yml (skips if exists)
```

Run one include directly, or syntax-check:
```bash
ansible-playbook -i localhost, -c local playbook.yml --tags <tag>
ansible-playbook -i localhost, -c local playbook.yml -e 'install_vim_shell_packages=false brew_install=false git_clone=false'
ansible-playbook --syntax-check -i localhost, -c local playbook.yml
```

The `key=value` form of `-e` passes **strings**, and ansible-core 2.21 rejects a bare string in
a `when:`. Keep `| bool` on any `when:` that tests a CLI-overridable flag. (The Taskfile uses the
YAML-dict form, `-e '{git_clone: true}'`, which parses as a real boolean.)

## Architecture

### Deployment flow

```
Taskfile.yml → ansible-galaxy (requirements.yml) → playbook.yml
                                                        ├── tasks/packages-arch.yml           (Arch pacman)
                                                        ├── tasks/packages-osx.yml            (Homebrew)
                                                        ├── tasks/install-dotfiles.yml        (rsync repo, remote only)
                                                        ├── tasks/jinga-templates.yml         (render .gitconfig, .zshenv, MCP configs)
                                                        ├── tasks/link-shell.yml              (symlinks dots/ → ~/.config/, ~/.zshrc, etc.)
                                                        ├── tasks/install-claude.yml          (copy dots/config/claude/ → ~/.claude/)
                                                        ├── tasks/windows-wsl.yml             (WSL only: glazewm+zebar+terminal configs → %USERPROFILE%)
                                                        ├── tasks/install-windsurf-workflows.yml
                                                        ├── tasks/install-shell-packages.yml
                                                        └── [when git_clone=true]
                                                            ├── tasks/git-modules-bradfordwagner.yml  (clone ~/workspace/github/bradfordwagner/*)  [git_clone_bw]
                                                            └── tasks/git-modules-github.yml                                                       [git_clone_os]
```

`git_clone_bw` / `git_clone_os` both default to `true`, so `-e git_clone=true` alone clones
everything; `task git_bw` / `task git_os` flip one off.

### Directory layout

- `dots/config/` — configs symlinked to `~/.config/<name>` (nvim, sway, waybar, tmux, alacritty, ghostty, etc.). Changes are live immediately — no `task bb` needed.
- `dots/shell/` — zsh files sourced via `~/.zshenv` → `env.sh.j2`. Load order: `palette.zsh` → `common.zsh` → `local.zsh` → `alias.zsh` → `git.zsh` → others (incl. `sessions.sh`). A new file needs a `source` line in `templates/env.sh.j2` and `task bb`.
- `dots/tmux/` — tmux.conf + tmuxinator sessions
- `templates/` — Jinja2 templates rendered by `tasks/jinga-templates.yml` into home-directory files
- `tasks/` — task files included from `playbook.yml`

### Variables

- `variables.yml` — committed defaults (alacritty/ghostty theme/font, MCP server paths/URLs, `user_name`).
- `variables.local.yml` — gitignored machine-local overrides, created by `task ilv`. Always wins; loaded with `ignore_errors: yes` if missing. Token/URL config goes here.

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
to deploy any change.

- Name subagents with a `bw-` prefix. `~/.claude/agents/` is a flat namespace shared with
  plugins and built-ins; the prefix marks ours.
- Pin `model:` explicitly; never `inherit`. `settings.json` sets the session model to
  `opus[1m]`, so `inherit` bills every subagent at the top tier with a 1M window. Start at
  `haiku` and escalate on evidence, sorted by **blast radius** rather than domain: an agent
  whose output you read before acting can stay low; one that mutates real infrastructure
  cannot, since its hardest instructions are *restraints* and smaller models hold those worst.

Agents (`dots/config/claude/agents/`): `bw-accountant`, `bw-k8s-author`. Commands
(`dots/config/claude/commands/`): `/cc`, `/bw-retro`, `/bw-role-update`, `/bw-image-rollout`, `/bw-pane`.
See `docs/claude-agents.md` for rationale (`session-usage.sh` carries its own in its header).

#### Keybinding conflicts

When adding or changing a keybinding, check every layer that can claim the chord:
- `dots/tmux/tmux.conf` — prefix `ctrl+space`; plain ctrl: `ctrl+h`; most others `ctrl+alt+*`
- `dots/config/sway/config` — `$mod = Mod1` (Alt); all bindings `alt+*`. Any `bindsym` change must update `dots/config/sway/keybindings.md` in the same change.
- `dots/config/aerospace/aerospace.toml` — `alt+*` (workspaces/focus), `ctrl+alt+*` (launchers)
- `dots/shell/bindkey.zsh` — zsh vi-mode: `ctrl+k` (chord leader), `ctrl+n`/`ctrl+p` (history), `ctrl+e`/`ctrl+o` (git); prompt only, not inside TUI apps
- `dots/config/glazewm/config.yaml` — global hook, takes the chord from everything else; see `docs/windows-wsl.md`
- `dots/config/claude/keybindings.json` — `ctrl+y` backgrounds the current task/agent

#### Image paste on WSL (`dots/shell_scripts/wsl-shims/`)

Pasting a screenshot with `ctrl+v` into Claude Code is broken on WSL by two interceptors:
- **Keys**: Windows Terminal's `ctrl+v` must stay `null` (text paste is `ctrl+shift+v`); GlazeWM must not bind it either.
- **Clipboard**: WSLg offers images only as `BI_BITFIELDS` `image/bmp`, which libvips cannot load, and `wl-paste` exits 0 on it, short-circuiting Claude's `||` chain. The `wsl-shims/wl-paste` shim fails `image/*` reads under WSL so the chain falls through to PowerShell; `dots/shell/common.linux.zsh` prepends the shim dir to `PATH`.

Verify with `wsl-shims/test-clipboard.sh` in a **new** shell (Claude inherits `PATH` at launch).
Reasoning is in the shim's header; diagnosis in `docs/windows-wsl.md`. Unfixed upstream as of 2.1.267.

### GlazeWM + Zebar + Windows Terminal (WSL only)

Configured by `tasks/windows-wsl.yml` (runs only when `ansible_facts.kernel` matches
`microsoft`). GlazeWM and Zebar configs are **copied** into `%USERPROFILE%\.glzr\` — a symlink
made from WSL on DrvFs is one Windows apps cannot follow. Windows Terminal is **merged**
(`dots/config/windows-terminal/merge-settings.py` folds in `settings.managed.json`, leaving
other keys as WT wrote them), since `profiles.list` and `defaultProfile` are per-machine GUIDs.

- GlazeWM's keyboard hook is global: `alt+;` and `alt+ctrl+hjkl` are reserved for tmux.
- All three are themed **Catppuccin Mocha**, matching `ghostty_theme` — retheme together.
- Reload after `task bb`: GlazeWM via tray icon or `alt+shift+r`; Zebar needs a process restart.

Any add/change/removal of a binding or workspace in `dots/config/glazewm/config.yaml` must
update **both** in the same change:
- `dots/config/glazewm/keybindings.md` — table + ASCII keyboard maps
- `dots/config/glazewm/keybindings.html` — keycap version, **published as an Artifact**;
  redeploy to the same URL (`https://claude.ai/code/artifact/b019cd7d-7a3f-4745-80ef-097fb739e209`)

See `docs/windows-wsl.md` for the layout table, workspace grid, `stack.cmd` accordion
workaround, and Zebar pack details.

### sessions (multi-repo worktrees)

`dots/shell/sessions.sh` defines `sessions new|add|delete` (or fzf picks the verb). A *session*
is one branch name spanning N repos: a `git worktree` of each under
`~/sessions/${name}/${repo}`, `sessions.md` copied in as the session's `CLAUDE.md`, a tmux
window, and one `bd init` beads tracker at the session root. Nothing touches the original
checkouts except advancing `origin/*`. `delete` never deletes branches and prompts when a
worktree is dirty or beads are open.

Overridable: `SESSIONS_ROOT`, `SESSIONS_TMUX`, `SESSIONS_TEMPLATE`, `SESSIONS_SCAN_DEPTH`.
See `docs/sessions.md` for repo-name resolution, `--no-track` branch base, beads flags, and why
the session root is not a git repo.

### MCP servers

Configured via `templates/cursor.mcp.json.j2` (→ `~/.cursor/mcp.json`):
- `argocd-mcp` — ArgoCD (pnpm/tsx), path `argocd_mcp_dir`
- `bw-mcp` — Bradford's Go MCP server, path `bradfordwagner_mcp_dir`

### Setup docs: `wsl.md` vs `coder.md`

Hand-run guides sharing the desktop stack (xrdp → Xorg → sway via `~/.xsession`, tmux/nvim
conflict notes) but targeting different hosts. Keep platform-specific steps in the right file.

- **`wsl.md`** — WSL2. Has systemd (`systemd=true` in `/etc/wsl.conf`), snaps, default Homebrew prefix (`/home/linuxbrew`); filesystem fully persistent.
- **`coder.md`** — bare Coder Kubernetes pod. **No systemd** (use `service`; firefox from Mozilla's APT repo, not the snap stub), no window manager, and `/` is **wiped on rebuild** — only `~/` (`/home/coder`, a PV) persists. Hence the `XDG_RUNTIME_DIR` guard in `templates/xsession.j2`, the `sesman.ini` socket-group fix, and the Homebrew symlink (`~/linuxbrew` ← `/home/linuxbrew/.linuxbrew`). Anything touching `/` must be re-run per rebuild or baked into the base image.

A change to the shared stack (e.g. the `.xsession`/sway launch) usually belongs in
`templates/xsession.j2` and should be reflected in **both** docs; a systemd/persistence/snap
detail belongs in exactly one.
