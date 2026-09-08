@echo off
rem stack.cmd -- GlazeWM's missing accordion layout, as a wrapper around one
rem focus or move command.
rem
rem   stack.cmd focus --direction left
rem   stack.cmd move --direction down
rem
rem Source of truth is dots/config/glazewm/stack.cmd; tasks/windows-wsl.yml
rem copies it to %USERPROFILE%\.glzr\glazewm\. glazewm.exe is on PATH from the
rem installer.
rem
rem GlazeWM 3.x has no stacked, tabbed or accordion layout -- a window is
rem tiling, floating, fullscreen or minimized, and that is the whole list. So
rem "this workspace is stacked" is expressed as "its focused window is
rem fullscreen", which alt+. toggles. That keeps the layout per-workspace and
rem stateless: there is no mode to be in and nothing to get out of sync.
rem
rem When the focused window is fullscreen: un-fullscreen it, run the command,
rem fullscreen whatever the command landed on. A fullscreen window keeps its
rem slot in the workspace tree, so this walks the workspace one full-size
rem window at a time in tree order. `focus --direction` on its own will not
rem traverse a fullscreen window, and `wm-cycle-focus` only rotates between the
rem tiling/floating/fullscreen groups, so the sandwich is what makes it work.
rem At either end of the stack the step fails and the same window is
rem re-fullscreened, which is a no-op.
rem
rem Otherwise this is a plain pass-through and the key behaves exactly as it
rem always did. Costs one extra IPC round trip (~70ms) unstacked, ~110ms
rem stacked. The `state` needle is case-sensitive on purpose: `prevState`
rem carries the same shape and must not match it.
setlocal
glazewm query focused | findstr /C:"\"state\":{\"type\":\"fullscreen\"" >nul
if errorlevel 1 (
  glazewm command %* >nul
) else (
  glazewm command set-tiling >nul
  glazewm command %* >nul
  glazewm command set-fullscreen >nul
)
