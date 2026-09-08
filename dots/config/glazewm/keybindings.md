# GlazeWM Keybindings

Reference table for keybindings defined in `dots/config/glazewm/config.yaml`.
The modifier is `alt` throughout. Update this file whenever a binding changes,
same rule as `dots/config/sway/keybindings.md`.

## Workspace grid

The left-hand block is 15 workspaces laid out as it sits under your hand —
`alt+<key>` focuses, `alt+shift+<key>` moves the focused window there and
follows it. That is the whole set — there is no number row. This mirrors
`dots/config/aerospace/aerospace.toml`, where every letter is a workspace.

```
                 alt + key  ->  focus workspace
           alt + shift + key  ->  move window + follow

  ┌─────┬─────┬─────┬─────┬─────┐
  │  Q  │  W  │  E  │  R  │  T  │      ws Q W E R T
  └─────┴─────┴─────┴─────┴─────┘
    ┌─────┬─────┬─────┬─────┬─────┐
    │  A  │  S  │  D  │  F  │  G  │    ws A S D F G
    └─────┴─────┴─────┴─────┴─────┘
      ┌─────┬─────┬─────┬─────┬─────┐
      │  Z  │  X  │  C  │  V  │  B  │  ws Z X C V B
      └─────┴─────┴─────┴─────┴─────┘
```

## The alt layer

Workspace keys are shown as `ws`; `--` is unbound.

```
 ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
 │ `  │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │ 9  │ 0  │ -  │ =  │
 │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │
 ├────┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┐
 │ TAB │ Q  │ W  │ E  │ R  │ T  │ Y  │ U  │ I  │ O  │ P  │ [  │ ]  │
 │ --  │ ws │ ws │ ws │ ws │ ws │ -- │ w- │ h- │ h+ │ w+ │prev│next│
 ├─────┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴────┤
 │ CAPS  │ A  │ S  │ D  │ F  │ G  │ H  │ J  │ K  │ L  │ ;  │  '    │
 │       │ ws │ ws │ ws │ ws │ ws │ ←  │ ↓  │ ↑  │ →  │ -- │ size  │
 ├───────┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴──┬─┴───────┤
 │  SHIFT   │ Z  │ X  │ C  │ V  │ B  │ N  │ M  │ ,  │ .  │  /      │
 │          │ ws │ ws │ ws │ ws │ ws │ -- │min │tile│full│ split    │
 └──────────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴─────────┘
      SPACE = cycle focus   ENTER = wt -f   ESC = recent workspace
```

`w-`/`w+` and `h-`/`h+` are the 2% width/height resize steps on `u`/`p` and
`i`/`o`. The whole number row is free, as are `alt+n` and `alt+y`.

## The alt+shift layer

```
 ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
 │ 1  │ 2  │ 3  │ 4  │ 5  │ 6  │ 7  │ 8  │ 9  │ 0  │ -  │ =  │ BS │
 │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │ -- │
 ├────┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴────┤
 │  Q  │ W  │ E  │ R  │ T  │ Y  │ U  │ I  │ O  │ P  │ [  │  ]     │
 │  mv │ mv │ mv │ mv │ mv │ -- │ -- │ -- │ -- │pause│ -- │  --    │
 ├─────┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───┴┬───────┤
 │  A   │ S  │ D  │ F  │ G  │ H  │ J  │ K  │ L  │ ;  │  '  │      │
 │  mv  │ mv │ mv │ mv │ mv │ ←  │ ↓  │ ↑  │ →  │ -- │ svc │      │
 ├──────┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴─┬──┴──────┤
 │        │ Z  │ X  │ C  │ V  │ B  │ N  │ M  │ ,  │ .  │  /      │
 │        │ mv │ mv │ mv │ mv │ mv │ -- │ -- │ -- │ -- │  --     │
 └────────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴─────────┘
                    SPACE = float + center
```

`←↓↑→` here move the focused window; `svc` enters the service mode below.
Adding ctrl gives one more chord: `alt+ctrl+shift+q` closes the window.

## Focus & movement

| Keybinding | Action |
|---|---|
| `alt+h/j/k/l` or arrows | Focus left/down/up/right — walks the stack on a stacked workspace |
| `alt+shift+h/j/k/l` or arrows | Move focused window — reorders the stack, stays full-size |
| `alt+space` | Cycle focus: tiling → floating → fullscreen |
| `alt+[` / `alt+]` | Focus prev / next active workspace |
| `alt+Escape` | Focus most recent workspace |
| service mode `h/j/k/l` | Move the whole workspace to the monitor in that direction |

Moving a window perpendicular to the current layout (e.g. `alt+shift+j` on a
side-by-side pair) inverts the workspace's tiling direction — that is how you
flip an existing row into a column. `alt+/` only sets where the *next* window
is inserted.

## Window state & layout

| Keybinding | Action |
|---|---|
| `alt+shift+space` | Toggle floating (centered) |
| `alt+,` | Toggle tiling — the return trip from floating |
| `alt+.` | Toggle fullscreen — also the stacked-layout toggle, see below |
| `alt+m` | Minimize |
| `alt+/` | Toggle tiling direction (where the next window goes) |
| `alt+ctrl+shift+q` | Close window (also `x` in service mode) |
| `alt+u` / `alt+p` | Width -2% / +2% |
| `alt+i` / `alt+o` | Height -2% / +2% |
| `alt+Enter` | Windows Terminal in focus mode (`wt -f`) |

## Binding modes

`alt+'` enters **resize** mode; `alt+shift+'` enters **service** mode. Both are
one-shot-ish: every command returns you to the default bindings.

A mode is exclusive, not additive — while one is active *every* other binding is
off, the whole workspace grid included. That is why the stacked layout below is
not a mode: you would not be able to change workspace while stacked.

| Mode | Key | Action |
|---|---|---|
| resize | `h/j/k/l` or arrows | Resize by 2% |
| resize | `Escape` / `Enter` / `alt+'` | Back to default |
| service | `Escape` | Reload config |
| service | `r` | Redraw all windows |
| service | `x` | Close focused window |
| service | `p` | Toggle pause (window management off) |
| service | `q` | Exit GlazeWM |
| service | `h/j/k/l` | Move workspace to the monitor left/down/up/right |
| service | `Enter` / `alt+shift+'` | Back to default |

Service mode exists because `alt+shift+e/r/w/q` are workspaces now. It mirrors
aerospace's `[mode.service.binding]`, down to `Escape` = reload-config.

## Why the punctuation

Freeing 15 letters displaced 15 commands. Where a counterpart exists in
`dots/config/aerospace/aerospace.toml`, the new home matches it:

| Command | Was | Now | Aerospace counterpart |
|---|---|---|---|
| Toggle tiling direction | `alt+v` | `alt+/` | `alt-slash` = `layout tiles horizontal vertical` |
| Resize mode | `alt+r` | `alt+'` | `alt-shift-semicolon` = `mode resize` |
| Service mode | — | `alt+shift+'` | `alt-shift-semicolon` = `mode service` |
| Recent workspace | `alt+d` | `alt+Escape` | `alt-esc` = `workspace-back-and-forth` |
| Toggle tiling | `alt+t` | `alt+,` | `alt-comma` (the other layout key) |
| Toggle fullscreen | `alt+f` | `alt+.` | `alt-comma` = `layout accordion` (see below) |
| Prev/next workspace | `alt+a` / `alt+s` | `alt+[` / `alt+]` | — |
| Move workspace to monitor | `alt+shift+a/s/d/f` | service mode `h/j/k/l` | `alt-shift-tab` |
| Close | `alt+shift+q` | `alt+ctrl+shift+q` | service `x` / `b` |
| Exit / reload / redraw | `alt+shift+e/r/w` | service mode `q` / `Esc` / `r` | `[mode.service.binding]` |

GlazeWM key names for punctuation are `oem_*` (`oem_question` = `/`,
`oem_quotes` = `'`, `oem_comma`, `oem_period`, `oem_open_brackets`,
`oem_close_brackets`); the full list is in `wm-platform/src/models/key.rs`.

## What the terminal stack claims

GlazeWM binds through a low-level keyboard hook, so anything it takes never reaches
Windows Terminal, tmux, nvim, or an RDP session. Two chords are off-limits for that
reason, even though GlazeWM would happily take them:

| Chord | Owner |
|---|---|
| `alt+;` | tmux `M-\;` — `resize-pane -Z`; hence resize mode on `alt+'` |
| `alt+ctrl+h/j/k/l` | tmux `C-M-hjkl` — `select-pane`; hence move-workspace in service mode |

`alt+h/j/k/l` does shadow tmux's vim-aware `M-hjkl` pane nav, but that one is unused —
`C-M-hjkl` is the pane-navigation chord that has to keep working.

Sway over RDP is the other victim: `$mod` is Alt there too, so GlazeWM eats every sway
binding before the RDP client sees it. Pause GlazeWM (`alt+shift+p`, or `p` in service
mode) before connecting.

## The stacked layout

GlazeWM has no tabbed, stacked or accordion *layout* — a window is tiling,
floating, fullscreen or minimized, and that is the whole list. So aerospace's
`alt-comma` (`layout accordion`) is faked, and the fake behaves the way the
aerospace one does: you turn the layout on for a workspace and then navigate it
with the ordinary focus keys.

| Keybinding | Action |
|---|---|
| `alt+.` | Stack / unstack the workspace (it is `toggle-fullscreen`) |
| `alt+h/j/k/l` | Walk the stack, one full-size window at a time |
| `alt+shift+h/j/k/l` | Reorder the stack, staying full-size on the window you moved |

**A workspace is "stacked" when its focused window is fullscreen.** There is no
mode and no stored state — the layout lives in the window's own state, so it is
per-workspace and cannot get out of sync. `alt+.` is the toggle.

`alt+h/j/k/l` and `alt+shift+h/j/k/l` run through
`dots/config/glazewm/stack.cmd`, which branches on that state. Not fullscreen:
plain `focus --direction` / `move --direction`, exactly as before. Fullscreen:
un-fullscreen, step, re-fullscreen whatever it landed on — a fullscreen window
keeps its slot in the workspace tree, so that walks the workspace one full-size
window at a time in tree order. At either end the step fails and the same window
is re-fullscreened, a no-op.

Three dead ends worth not re-discovering:

- **A binding mode cannot do this.** Modes are exclusive: with one active, every
  other binding is dead, so a persistent stack mode costs you the workspace grid.
  Verified by injecting `alt+t` with a mode active (nothing) and without it (the
  workspace switched).
- **Neither `focus --direction` nor `wm-cycle-focus` will traverse fullscreen
  windows.** The first ignores them; the second only rotates between the
  tiling/floating/fullscreen *groups*, so with everything fullscreen it is a
  no-op. Hence the un-fullscreen/step/re-fullscreen sandwich.
- **There is no neighbour peek.** aerospace's `accordion-padding` has no
  counterpart: `resize --width 75%` is *relative*, not absolute, so it drives the
  focused tile to the 0.99 clamp and its sibling to 0.01, and no equalize command
  exists to undo the drift.

The cost is one extra IPC round trip on the focus keys: ~70ms unstacked (a query
plus the command), ~110ms stacked (four). `shell-exec --hide-window` keeps the
`cmd` console from flashing.
