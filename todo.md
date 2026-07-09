# todo

## sway - worth adding

- [x] **waybar** — status bar (workspaces, clock, battery, etc.); more configurable than sway's built-in bar
- [ ] **wofi** — native Wayland app launcher; rofi works but runs under XWayland
- [x] **grim** — Wayland screenshot capture (X11 tools like scrot won't work under Wayland)
- [x] **slurp** — region selector used with grim for partial screenshots
- [x] **wl-clipboard** — `wl-copy`/`wl-paste` for Wayland; `xclip` doesn't work in native Wayland sessions
- [x] **fonts-font-awesome** — icon font used by waybar for battery, wifi, volume glyphs
- [ ] **nwg-look** — GUI to set GTK theme/font/cursor consistently under Wayland
- [ ] **thunar** — lightweight XFCE file manager for when a GUI file browser is needed
- [ ] **swayfx** — sway fork with blur/shadows/rounded corners/animations; no apt package on Ubuntu/WSL, requires building from source (scenefx + swayfx via meson/ninja) — holding off until network bandwidth supports rebuilds
  - what I actually want: smooth window move/resize animations and workspace-switch slide transitions (not just the open/close fade, which is the only animation in the current 0.5.3 release)
  - move/resize animations merged to master via PR #388 (2026-01-10) but **not in a tagged release yet** (latest release 0.5.3 is 2025-06-28, predates the merge) — only available via `swayfx-git`/building master
  - master currently has open, unresolved crash bugs in that animation code: #519 (heap-use-after-free in `transaction_apply`/`animation_manager.c` when closing windows, fix identified but unmerged) and #526 (malloc corruption crash on closing a floating window) — animations are not stable yet even on master
  - workspace-switch slide transition (the niri-style effect) is still blocked: PR #269 (touchpad-gesture workspace switching) explicitly deferred animations until move animations landed, and that PR itself is still open/unmerged — so this specific feature doesn't exist yet in any form
  - no committed timeline from maintainers; given move-animations took ~2 years from issue to merge and still isn't in a release 6 months later, I'd guess workspace-switch animation is realistically 6-12+ months out, contingent on the crash bugs getting fixed first — reassess before attempting a build
  - move/resize animations are already on master (per #388) even though workspace-switch isn't — may be worth checking out and building master just to test move/resize once bandwidth allows; no prebuilt binaries exist for Ubuntu/WSL (GitHub releases are source-only tarballs, no distro package), so this always means compiling from source
