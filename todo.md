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
  - **tested 2026-07-09: dead end on this setup.** Built master (commit `33cb07d3`, includes PR #388) in `~/tmp/swayfx` with scenefx 0.5 + wlroots 0.20.2 as meson subprojects — compiled clean (719 targets), but running it fails immediately: `Cannot create GLES2 renderer: no DRM FD available` / `Failed to create renderer`. scenefx's `fx_renderer` hard-requires a real DRM render node for GBM buffer allocation (`subprojects/scenefx/render/fx_renderer/fx_renderer.c:320-323`) and has no software fallback — unlike vanilla sway, which is running fine right now in this same environment via wlroots' Pixman software-renderer fallback (no `/dev/dri` here, confirmed earlier: xorgxrdp's `rdpPreInit: /dev/dri/renderD128 open failed`)
  - only theoretical way around it: WSLg (Windows' native WSL GUI integration, `/dev/dxg` + Mesa D3D12) exposes a real `/dev/dri/renderD128`-backed node in some configs — but that means replacing the xrdp+XFCE remote-desktop mechanism entirely, not just a sway/swayfx change. Not worth pursuing unless the xrdp setup itself is being reconsidered.
  - conclusion: shelve this — no amount of waiting for the animation/crash-bug fixes helps, since the renderer won't initialize at all on this hardware/setup
