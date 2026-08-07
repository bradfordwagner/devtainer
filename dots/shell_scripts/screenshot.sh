#!/usr/bin/env bash
# Screenshot -> clipboard (+ ~/screenshots/<timestamp>.png).
#
#   screenshot.sh          # select a region with slurp
#   screenshot.sh full     # whole screen
#
# grim is the preferred path: it asks the compositor for the frame over
# wlr-screencopy. But grim buffers that frame in a wl_shm pool, which glibc
# backs with a file in /dev/shm. On a Coder pod /dev/shm is the Kubernetes
# default 64M, and sway's own X11-backend output buffers already pin ~60M of it
# at 3440x1440 -- so grim's ~20M allocation faults on write and the process
# dies with SIGBUS (exit 135), silently, leaving a 0-byte file. `-g` and `-s`
# don't help: screencopy always hands over a full-size frame.
#
# When that happens, fall back to the outer X server. sway here runs nested
# inside the xrdp Xorg, so that Xorg's root window *is* the sway screen, and
# xwd reads it with plain XGetImage over the X socket -- no /dev/shm at all.
#
# The real fix is to give the pod a bigger /dev/shm (see coder.md); this script
# just keeps the hotkey working either way.

set -uo pipefail

# sway's exec inherits xrdp's minimal PATH, which has no brew prefix -- and the
# netpbm fallback below is installed there.
[ -d /home/linuxbrew/.linuxbrew/bin ] && PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

mode="${1:-region}"
outdir="${HOME}/screenshots"
out="${outdir}/$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$outdir"

die() { echo "screenshot: $*" >&2; exit 1; }

geom=""
if [ "$mode" != full ]; then
  geom="$(slurp)" || exit 0 # cancelled with escape
fi

# grim leaves a 0-byte file when it SIGBUSes, so check the size, not just $?.
if [ -n "$geom" ]; then
  grim -g "$geom" "$out"
else
  grim "$out"
fi
if [ ! -s "$out" ]; then
  rm -f "$out"

  # sway's own DISPLAY is the X server it is nested in -- Xwayland's DISPLAY
  # (what we would otherwise inherit) points at the wrong screen.
  swaypid="$(pgrep -x sway | head -1)"
  [ -n "$swaypid" ] || die "grim failed and sway is not running"
  display="$(tr '\0' '\n' < "/proc/${swaypid}/environ" | sed -n 's/^DISPLAY=//p' | head -1)"
  [ -n "$display" ] || die "grim failed and no outer X display to fall back to"

  # brew's imagemagick is built without X11, so it has no xwd decoder -- netpbm
  # does the conversion instead.
  command -v xwdtopnm >/dev/null || die "grim failed; xwd fallback needs netpbm (brew install netpbm)"

  # The outer root window can be bigger than sway's output -- sway comes up at
  # the small mode pinned in its config until sway_select_display.sh bumps it --
  # so trim a full-screen capture down to what sway is actually drawing.
  if [ -z "$geom" ] && command -v jq >/dev/null; then
    geom="$(swaymsg -t get_outputs |
      jq -r '[.[] | select(.active)][0].rect | "\(.x),\(.y) \(.width)x\(.height)"')"
  fi

  crop=(cat)
  if [ -n "$geom" ]; then
    # slurp prints "X,Y WxH"
    xy="${geom% *}" wh="${geom#* }"
    crop=(pnmcut -left "${xy%,*}" -top "${xy#*,}" -width "${wh%x*}" -height "${wh#*x}")
  fi
  xwd -root -display "$display" | xwdtopnm 2>/dev/null | "${crop[@]}" | pnmtopng > "$out" \
    || die "xwd fallback failed on display $display"
fi

wl-copy -t image/png < "$out"
echo "screenshot: $out" >&2
