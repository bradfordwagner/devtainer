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
| `alt+h/j/k/l` or arrows | Focus left/down/up/right |
| `alt+shift+h/j/k/l` or arrows | Move focused window |
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
| `alt+.` | Toggle fullscreen |
| `alt+m` | Minimize |
| `alt+/` | Toggle tiling direction (where the next window goes) |
| `alt+ctrl+shift+q` | Close window (also `x` in service mode) |
| `alt+u` / `alt+p` | Width -2% / +2% |
| `alt+i` / `alt+o` | Height -2% / +2% |
| `alt+Enter` | Windows Terminal in focus mode (`wt -f`) |

## Binding modes

`alt+'` enters **resize** mode; `alt+shift+'` enters **service** mode. Both are
one-shot-ish: every command returns you to the default bindings.

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
| Toggle fullscreen | `alt+f` | `alt+.` | — |
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

## Not available in GlazeWM

No tabbed, stacked, or accordion layout — the aerospace `alt-comma`
(`layout accordion`) idiom has no counterpart here. Fullscreen (`alt+.`) is the
only stacking-ish state.
