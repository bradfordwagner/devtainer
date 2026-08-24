#!/bin/zsh

# aerospace_float_center.sh — toggle the focused window between a centered
# floating box and its tiled slot. Rough analogue of the sway binding
# `floating toggle; resize set width 65 ppt height 80 ppt; move position center`.
#
#   tiled   -> float + center at WIDTH_PCT x HEIGHT_PCT of its display
#   floating-> re-tile and restore it next to the neighbor it had before floating
#
# AeroSpace has no positioning/percentage-resize command and does not remember a
# floated window's place in the tree, so we:
#   * set geometry via the macOS Accessibility API (multi-monitor aware), and
#   * stash the pre-float neighbor, then walk the window back beside it on return.
# The restore is best-effort: simple rows restore exactly; nested/mixed layouts
# may land close. Worst case the window is still tiled, just not in the old slot.
#
# Usage: aerospace_float_center.sh [WIDTH_PCT] [HEIGHT_PCT]   (defaults: 65 80)
#
# Requires Accessibility permission for whatever drives System Events (AeroSpace
# when triggered from a keybinding; the terminal when run by hand).

wpct="${1:-65}"
hpct="${2:-80}"

focused_id() { aerospace list-windows --focused --format '%{window-id}' 2>/dev/null; }
state_file_for() { echo "/tmp/aerospace-float-center-${1}.state"; }

w_id=$(focused_id)
[[ -z "${w_id}" ]] && exit 0
layout=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null)
state_file=$(state_file_for "${w_id}")

# ---------------------------------------------------------------------------
# floating -> tiling: re-tile and walk back next to the stored neighbor
# ---------------------------------------------------------------------------
if [[ "${layout}" == "floating" ]]; then
  anchor=""; rel=""; prevdir=""; nextdir=""
  if [[ -f "${state_file}" ]]; then
    IFS='|' read -r anchor rel prevdir nextdir < "${state_file}"
    rm -f "${state_file}"
  fi

  aerospace layout tiling >/dev/null 2>&1 || true

  # nothing to restore against (was a lone window, or neighbor since closed)
  [[ -z "${anchor}" ]] && exit 0
  aerospace list-windows --workspace focused --format '%{window-id}' 2>/dev/null \
    | grep -qx "${anchor}" || exit 0

  # direction to nudge our window so the anchor becomes its immediate neighbor
  if [[ "${rel}" == "after" ]]; then movedir="${prevdir}"; else movedir="${nextdir}"; fi

  # walk at most N steps; stop once the anchor sits immediately in `movedir`
  i=0
  while (( i < 30 )); do
    aerospace focus --window-id "${w_id}" >/dev/null 2>&1
    aerospace focus "${movedir}" >/dev/null 2>&1
    [[ "$(focused_id)" == "${anchor}" ]] && break
    aerospace focus --window-id "${w_id}" >/dev/null 2>&1
    aerospace move "${movedir}" >/dev/null 2>&1 || break
    (( i++ ))
  done
  aerospace focus --window-id "${w_id}" >/dev/null 2>&1
  exit 0
fi

# ---------------------------------------------------------------------------
# tiling -> floating: record neighbor, then float + center
# ---------------------------------------------------------------------------
parent=$(aerospace list-windows --focused --format '%{window-parent-container-layout}' 2>/dev/null)
if [[ "${parent}" == v_* ]]; then prevdir="up"; nextdir="down"; else prevdir="left"; nextdir="right"; fi

# prefer the previous-direction neighbor as the anchor; fall back to the next one
aerospace focus "${prevdir}" >/dev/null 2>&1
neighbor=$(focused_id)
if [[ -n "${neighbor}" && "${neighbor}" != "${w_id}" ]]; then
  rel="after"   # our window belongs just after the anchor
else
  aerospace focus --window-id "${w_id}" >/dev/null 2>&1
  aerospace focus "${nextdir}" >/dev/null 2>&1
  neighbor=$(focused_id)
  rel="before"  # our window belongs just before the anchor
fi
[[ "${neighbor}" == "${w_id}" ]] && neighbor=""   # lone window on this workspace
aerospace focus --window-id "${w_id}" >/dev/null 2>&1

echo "${neighbor}|${rel}|${prevdir}|${nextdir}" > "${state_file}"

aerospace layout floating >/dev/null 2>&1 || true

osascript -l JavaScript - "${wpct}" "${hpct}" <<'JXA'
function run(argv) {
  ObjC.import('AppKit');
  const wpct = parseInt(argv[0], 10) / 100;
  const hpct = parseInt(argv[1], 10) / 100;

  const se = Application('System Events');
  se.includeStandardAdditions = true;
  const proc = se.processes.whose({ frontmost: true })[0];
  const win = proc.windows[0];

  // current geometry in top-left (flipped) global coords
  const [px, py] = win.position();
  const [pw, ph] = win.size();
  const cx = px + pw / 2;
  const cy = py + ph / 2;

  // primary display full height — reference for flipped<->Cocoa conversion
  const screens = $.NSScreen.screens;
  const primaryH = screens.objectAtIndex(0).frame.size.height;

  // find the screen whose (flipped) visible frame contains the window center
  let target = null;
  for (let i = 0; i < screens.count; i++) {
    const s = screens.objectAtIndex(i);
    const vf = s.visibleFrame; // Cocoa: bottom-left origin
    const fx = vf.origin.x;
    const fy = primaryH - (vf.origin.y + vf.size.height); // -> flipped top
    const fw = vf.size.width;
    const fh = vf.size.height;
    if (cx >= fx && cx <= fx + fw && cy >= fy && cy <= fy + fh) {
      target = { x: fx, y: fy, w: fw, h: fh };
      break;
    }
  }
  if (!target) {
    const vf = screens.objectAtIndex(0).visibleFrame;
    target = { x: vf.origin.x, y: primaryH - (vf.origin.y + vf.size.height),
               w: vf.size.width, h: vf.size.height };
  }

  const w = Math.round(target.w * wpct);
  const h = Math.round(target.h * hpct);
  const x = Math.round(target.x + (target.w - w) / 2);
  const y = Math.round(target.y + (target.h - h) / 2);

  win.position = [x, y];
  win.size = [w, h];
}
JXA
