# CLAUDE.md

This file tell Claude Code (claude.ai/code) how work code in this repo.

## What this repo is

Bradford personal dotfiles ("devtainer"). Ansible = deploy engine; `go-task` (Taskfile.yml) = task runner. Playbook symlink configs, render Jinja2 templates, install packages — no copy files, except `install-dotfiles.yml` (sync repo when remote) and copy-tasks below.

## Detail docs

This file = map; depth live next to thing it describe. Keep that way — 40k-char budget, already blow past once.

| Doc | Covers |
|---|---|
| `docs/claude-agents.md` | Every subagent and agent script, with rationale |
| `docs/windows-wsl.md` | GlazeWM / Zebar / Windows Terminal layout, keybindings, WSL image-paste diagnosis |
| `docs/sessions.md` | Multi-repo worktree sessions, in full |
| `dots/config/glazewm/keybindings.md` | GlazeWM binding table + keyboard maps |
| `dots/config/sway/keybindings.md` | sway binding table |
| `dots/config/zebar/README.md` | Vendored Zebar pack, theming |
| `wsl.md` / `coder.md` | Host setup guides |

Agent scripts in `dots/config/claude/scripts/` hold full reasoning in own header comments — read those first, before docs.

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

Run one include direct, or syntax-check:
```bash
ansible-playbook -i localhost, -c local playbook.yml --tags <tag>
ansible-playbook -i localhost, -c local playbook.yml -e 'install_vim_shell_packages=false brew_install=false git_clone=false'
ansible-playbook --syntax-check -i localhost, -c local playbook.yml
```

`key=value` form of `-e` pass **strings**, and ansible-core 2.21 reject bare string in `when:`. Keep `| bool` on any `when:` that test CLI-overridable flag. (Taskfile use YAML-dict form, `-e '{git_clone: true}'`, which parse as real boolean.)

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

`git_clone_bw` / `git_clone_os` both default `true`, so `-e git_clone=true` alone clone everything; `task git_bw` / `task git_os` flip one off.

### Directory layout

- `dots/config/` — configs symlinked to `~/.config/<name>` (nvim, sway, waybar, tmux, alacritty, ghostty, etc.). Changes live now — no `task bb`.
- `dots/shell/` — zsh files sourced via `~/.zshenv` → `env.sh.j2`. Load order: `palette.zsh` → `common.zsh` → `local.zsh` → `alias.zsh` → `git.zsh` → others (incl. `sessions.sh`). New file need `source` line in `templates/env.sh.j2` plus `task bb`.
- `dots/tmux/` — tmux.conf + tmuxinator sessions
- `templates/` — Jinja2 templates rendered by `tasks/jinga-templates.yml` into home-dir files
- `tasks/` — task files included from `playbook.yml`

### Variables

- `variables.yml` — committed defaults (alacritty/ghostty theme/font, MCP server paths/URLs, `user_name`).
- `variables.local.yml` — gitignored machine-local overrides, made by `task ilv`. Always win; load with `ignore_errors: yes` if missing. Token/URL config go here.

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

`dots/config/claude/` hold slash commands, subagents, agent scripts, keybindings — all **copied** (not symlinked) into `~/.claude/` by `tasks/install-claude.yml`. Re-run `task bb` to deploy any change.

- Name subagents with `bw-` prefix. `~/.claude/agents/` = flat namespace shared with plugins and built-ins; prefix mark ours.
- Pin `model:` explicit; never `inherit`. `settings.json` set session model to `opus[1m]`, so `inherit` bill every subagent at top tier with 1M window. Start at `haiku`, escalate on evidence, sort by **blast radius** not domain: agent whose output you read before acting can stay low; one that mutate real infrastructure cannot — its hardest instructions are *restraints*, and smaller models hold those worst.

Agents (`dots/config/claude/agents/`): `bw-accountant`, `bw-k8s-author`. Commands
(`dots/config/claude/commands/`): `/cc`, `/bw-retro`, `/bw-role-update`, `/bw-image-rollout`, `/bw-pane`.
See `docs/claude-agents.md` for rationale (`session-usage.sh` carry own in its header).

#### Keybinding conflicts

When add or change keybinding, check every layer that can grab the chord:
- `dots/tmux/tmux.conf` — prefix `ctrl+space`; plain ctrl: `ctrl+h`; most others `ctrl+alt+*`
- `dots/config/sway/config` — `$mod = Mod1` (Alt); all bindings `alt+*`. Any `bindsym` change must update `dots/config/sway/keybindings.md` in same change.
- `dots/config/aerospace/aerospace.toml` — `alt+*` (workspaces/focus), `ctrl+alt+*` (launchers)
- `dots/shell/bindkey.zsh` — zsh vi-mode: `ctrl+k` (chord leader), `ctrl+n`/`ctrl+p` (history), `ctrl+e`/`ctrl+o` (git); prompt only, not inside TUI apps
- `dots/config/glazewm/config.yaml` — global hook, take chord from everything else; see `docs/windows-wsl.md`
- `dots/config/claude/keybindings.json` — `ctrl+y` background current task/agent

#### Image paste on WSL (`dots/shell_scripts/wsl-shims/`)

Paste screenshot with `ctrl+v` into Claude Code broken on WSL by two interceptors:
- **Keys**: Windows Terminal `ctrl+v` must stay `null` (text paste = `ctrl+shift+v`); GlazeWM must not bind it either.
- **Clipboard**: WSLg offer images only as `BI_BITFIELDS` `image/bmp`, which libvips cannot load, and `wl-paste` exit 0 on it, short-circuiting Claude `||` chain. The `wsl-shims/wl-paste` shim fail `image/*` reads under WSL so chain fall through to PowerShell; `dots/shell/common.linux.zsh` prepend shim dir to `PATH`.

Verify with `wsl-shims/test-clipboard.sh` in **new** shell (Claude inherit `PATH` at launch).
Reasoning in shim header; diagnosis in `docs/windows-wsl.md`. Unfixed upstream as of 2.1.267.

### GlazeWM + Zebar + Windows Terminal (WSL only)

Configured by `tasks/windows-wsl.yml` (run only when `ansible_facts.kernel` match `microsoft`). GlazeWM and Zebar configs **copied** into `%USERPROFILE%\.glzr\` — symlink made from WSL on DrvFs is one Windows apps cannot follow. Windows Terminal **merged** (`dots/config/windows-terminal/merge-settings.py` fold in `settings.managed.json`, leave other keys as WT wrote them), since `profiles.list` and `defaultProfile` = per-machine GUIDs.

- GlazeWM keyboard hook global: `alt+;` and `alt+ctrl+hjkl` reserved for tmux.
- All three themed **Catppuccin Mocha**, match `ghostty_theme` — retheme together.
- Reload after `task bb`: GlazeWM via tray icon or `alt+shift+r`; Zebar need process restart.

Any add/change/removal of binding or workspace in `dots/config/glazewm/config.yaml` must update **both** in same change:
- `dots/config/glazewm/keybindings.md` — table + ASCII keyboard maps
- `dots/config/glazewm/keybindings.html` — keycap version, **published as Artifact**;
  redeploy to same URL (`https://claude.ai/code/artifact/b019cd7d-7a3f-4745-80ef-097fb739e209`)

See `docs/windows-wsl.md` for layout table, workspace grid, `stack.cmd` accordion workaround, and Zebar pack details.

### sessions (multi-repo worktrees)

`dots/shell/sessions.sh` define `sessions new|add|delete` (or fzf pick the verb). A *session* = one branch name spanning N repos: `git worktree` of each under `~/sessions/${name}/${repo}`, `sessions.md` copied in as session `CLAUDE.md`, a tmux window, and one `bd init` beads tracker at session root. Nothing touch original checkouts except advancing `origin/*`. `delete` never delete branches, and prompt when worktree dirty or beads open.

Overridable: `SESSIONS_ROOT`, `SESSIONS_TMUX`, `SESSIONS_TEMPLATE`, `SESSIONS_SCAN_DEPTH`.
See `docs/sessions.md` for repo-name resolution, `--no-track` branch base, beads flags, and why session root not a git repo.

### MCP servers

Configured via `templates/cursor.mcp.json.j2` (→ `~/.cursor/mcp.json`):
- `argocd-mcp` — ArgoCD (pnpm/tsx), path `argocd_mcp_dir`
- `bw-mcp` — Bradford Go MCP server, path `bradfordwagner_mcp_dir`

### Setup docs: `wsl.md` vs `coder.md`

Hand-run guides sharing the desktop stack (xrdp → Xorg → sway via `~/.xsession`, tmux/nvim conflict notes) but target different hosts. Keep platform-specific steps in right file.

- **`wsl.md`** — WSL2. Has systemd (`systemd=true` in `/etc/wsl.conf`), snaps, default Homebrew prefix (`/home/linuxbrew`); filesystem fully persistent.
- **`coder.md`** — bare Coder Kubernetes pod. **No systemd** (use `service`; firefox from Mozilla APT repo, not snap stub), no window manager, and `/` **wiped on rebuild** — only `~/` (`/home/coder`, a PV) persist. Hence `XDG_RUNTIME_DIR` guard in `templates/xsession.j2`, `sesman.ini` socket-group fix, and Homebrew symlink (`~/linuxbrew` ← `/home/linuxbrew/.linuxbrew`). Anything touching `/` must re-run per rebuild or bake into base image.

Change to shared stack (e.g. `.xsession`/sway launch) usually belong in `templates/xsession.j2` and should show in **both** docs; systemd/persistence/snap detail belong in exactly one.