# Sway Keybindings

Reference table for keybindings defined in `dots/config/sway/config`. `$mod` is `Mod1` (Alt).

## Basics

| Keybinding | Action |
|---|---|
| `$mod+Return` | Open terminal (`$term`) |
| `$mod+Shift+q` | Kill focused window |
| `$mod+d` | Open launcher (`$menu` — rofi) |
| `$mod+Shift+c` | Reload sway config |
| `$mod+Shift+e` | Exit sway (confirmation prompt) |
| `$mod` + drag / `$mod` + right-click | Move / resize floating windows (`floating_modifier`) |

## Focus & Movement

| Keybinding | Action |
|---|---|
| `$mod+h` / `$mod+Left` | Focus left |
| `$mod+j` / `$mod+Down` | Focus down |
| `$mod+k` / `$mod+Up` | Focus up |
| `$mod+l` / `$mod+Right` | Focus right |
| `$mod+Shift+h` / `$mod+Shift+Left` | Move focused window left |
| `$mod+Shift+j` / `$mod+Shift+Down` | Move focused window down |
| `$mod+Shift+k` / `$mod+Shift+Up` | Move focused window up |
| `$mod+Shift+l` / `$mod+Shift+Right` | Move focused window right |
| `$mod+a` | Focus parent container |

## Workspaces

| Keybinding | Action |
|---|---|
| `$mod+1` … `$mod+9`, `$mod+0` | Switch to workspace 1–10 |
| `$mod+Shift+1` … `$mod+Shift+9`, `$mod+Shift+0` | Move focused container to workspace 1–10 |

## Layout

| Keybinding | Action |
|---|---|
| `$mod+b` | Split horizontal |
| `$mod+v` | Split vertical |
| `$mod+s` | Layout: stacking |
| `$mod+w` | Layout: tabbed |
| `$mod+e` | Layout: toggle split |
| `$mod+f` | Toggle fullscreen |
| `$mod+Shift+space` | Toggle floating (resizes to 65%×80% and forces pixel border when floating) |
| `$mod+space` | Toggle focus between tiling/floating |
| `$mod+c` | Center focused floating window |
| `$mod+p` | Toggle waybar visibility |

## Scratchpad

| Keybinding | Action |
|---|---|
| `$mod+Shift+minus` | Move focused window to scratchpad |
| `$mod+minus` | Show/cycle scratchpad windows |

## Resize Mode

| Keybinding | Action |
|---|---|
| `$mod+r` | Enter resize mode |
| `h` / `Left` | Shrink width |
| `l` / `Right` | Grow width |
| `k` / `Up` | Shrink height |
| `j` / `Down` | Grow height |
| `$mod+c` | Center window (while resizing) |
| `$mod+Shift+h/j/k/l` or arrows | Move floating window (while resizing) |
| `Return` / `Escape` | Return to default mode |

## Utilities & Media Keys

| Keybinding | Action |
|---|---|
| `XF86AudioMute` | Toggle mute (default sink) |
| `XF86AudioLowerVolume` | Volume down 5% |
| `XF86AudioRaiseVolume` | Volume up 5% |
| `XF86AudioMicMute` | Toggle mic mute (default source) |
| `XF86MonBrightnessDown` | Brightness down 5% |
| `XF86MonBrightnessUp` | Brightness up 5% |
| `Print` | Screenshot (grim) |
| `Mod4+Shift+4` | Select region screenshot to clipboard (grim + slurp + wl-copy) |
