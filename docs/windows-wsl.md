# GlazeWM + Zebar + Windows Terminal (WSL only)

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


## Image paste on WSL (`dots/shell_scripts/wsl-shims/`)

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

