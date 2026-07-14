# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Bradford's personal dotfiles ("devtainer"). Ansible is the deployment engine; `go-task` (Taskfile.yml) is the task runner. Running the playbook symlinks configs, renders Jinja2 templates, and installs packages — it does not copy files except for `install-dotfiles.yml` (which syncs the repo itself when running remotely).

## Common commands

```bash
task              # full install: brew + git clones + vim/shell packages
task bb           # bare-bones: links + templates only, no package installs
task git          # git clones only: syncs all workspace repos (bradfordwagner + github modules)
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
                                                        ├── tasks/install-windsurf-workflows.yml
                                                        ├── tasks/install-shell-packages.yml
                                                        └── [when git_clone=true]
                                                            ├── tasks/git-modules-bradfordwagner.yml  (clone ~/workspace/github/bradfordwagner/*)
                                                            └── tasks/git-modules-github.yml
```

### Directory layout

- `dots/config/` — configs symlinked to `~/.config/<name>` (nvim, sway, waybar, tmux, alacritty, ghostty, etc.). Changes here are live immediately — no need to run `task bb`.
- `dots/shell/` — zsh files sourced via `~/.zshenv` → `env.sh.j2`. Load order: `palette.zsh` → `common.zsh` → `local.zsh` → `alias.zsh` → `git.zsh` → others
- `dots/tmux/` — tmux.conf + tmuxinator sessions
- `templates/` — Jinja2 templates rendered by `tasks/jinga-templates.yml` into home directory files
- `tasks/` — individual Ansible task files included from `playbook.yml`

### Variables

- `variables.yml` — defaults (committed, safe to read). Covers alacritty/ghostty theme/font, MCP server paths/URLs, `user_name`.
- `variables.local.yml` — machine-local overrides (gitignored). Created via `task ilv`. Always takes precedence; loaded with `ignore_errors: yes` if missing.

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

### MCP servers

Configured via `templates/cursor.mcp.json.j2` (rendered to `~/.cursor/mcp.json`):
- `argocd-mcp` — ArgoCD MCP server (pnpm/tsx), path set via `argocd_mcp_dir`
- `bw-mcp` — Bradford's custom Go MCP server, path set via `bradfordwagner_mcp_dir`

Token/URL config goes in `variables.local.yml`.
