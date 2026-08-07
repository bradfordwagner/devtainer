#!/usr/bin/env bash
# Screenshot -> clipboard (+ ~/screenshots/<timestamp>.png).
#
#   screenshot.sh          # select a region
#   screenshot.sh full     # whole screen
#
# grim/slurp are the preferred path. Both, though, need a full-screen wl_shm
# buffer -- grim to receive the frame, slurp to draw its overlay -- and glibc
# backs a wl_shm pool with a file in /dev/shm. On a Coder pod /dev/shm is the
# Kubernetes default 64M, and sway's own X11-backend output buffers already pin
# most of that at 3440x1440, so the ~20M allocation faults on write and the
# process dies with SIGBUS (exit 135). grim does it silently, leaving a 0-byte
# file; slurp does it as a screen flash with no selection. grim's `-g` and `-s`
# don't help -- screencopy always hands over a full-size frame.
#
# So when either dies, fall back to the outer X server. sway here runs nested
# inside the xrdp Xorg, so that Xorg's root window *is* the sway screen: slop
# selects on it and xwd reads it with plain XGetImage over the X socket. Neither
# touches /dev/shm.
#
# The real fix is to give the pod a bigger /dev/shm (see coder.md); this script
# just keeps the hotkey working either way.

set -uo pipefail

# sway's exec inherits xrdp's minimal PATH, which has no brew prefix -- and the
# netpbm conversion below is installed there.
[ -d /home/linuxbrew/.linuxbrew/bin ] && PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

mode="${1:-region}"
outdir="${HOME}/screenshots"
out="${outdir}/$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$outdir"

die() { echo "screenshot: $*" >&2; exit 1; }

# sway's own DISPLAY is the X server it is nested in. Xwayland's DISPLAY, which
# we would otherwise inherit, points at the wrong screen.
outer_display() {
  local swaypid
  swaypid="$(pgrep -x sway | head -1)" || return 1
  tr '\0' '\n' < "/proc/${swaypid}/environ" | sed -n 's/^DISPLAY=//p' | head -1
}

geom=""
x11=0 # set when geometry is in outer-root coordinates rather than sway's
if [ "$mode" != full ]; then
  geom="$(slurp 2>/dev/null)"
  rc=$?
  if [ "$rc" -gt 128 ]; then
    # killed by a signal -- slurp could not get its overlay buffer
    display="$(outer_display)"
    [ -n "$display" ] || die "slurp died and no outer X display to fall back to"
    command -v slop >/dev/null || die "slurp died; region select needs slop (apt install slop)"
    geom="$(DISPLAY="$display" slop -f '%x,%y %wx%h' 2>/dev/null)" || exit 0
    x11=1
  elif [ "$rc" -ne 0 ]; then
    exit 0 # cancelled with escape
  fi
  [ -n "$geom" ] || exit 0
fi

# grim leaves a 0-byte file when it SIGBUSes, so check the size, not just $?.
if [ "$x11" -eq 0 ]; then
  if [ -n "$geom" ]; then
    grim -g "$geom" "$out"
  else
    grim "$out"
  fi
fi
if [ ! -s "$out" ]; then
  rm -f "$out"

  display="${display:-$(outer_display)}"
  [ -n "$display" ] || die "grim failed and no outer X display to fall back to"

  # brew's imagemagick is built without X11, so it has no xwd decoder -- netpbm
  # does the conversion instead.
  command -v xwdtopnm >/dev/null || die "grim failed; xwd needs netpbm (brew install netpbm)"

  # The outer root window can be bigger than sway's output -- sway comes up at
  # the small mode pinned in its config until sway_select_display.sh bumps it --
  # so trim a full-screen capture down to what sway is actually drawing.
  if [ -z "$geom" ] && command -v jq >/dev/null; then
    geom="$(swaymsg -t get_outputs |
      jq -r '[.[] | select(.active)][0].rect | "\(.x),\(.y) \(.width)x\(.height)"')"
  fi

  crop=(cat)
  if [ -n "$geom" ]; then
    # slurp and slop both print "X,Y WxH"
    xy="${geom% *}" wh="${geom#* }"
    crop=(pnmcut -left "${xy%,*}" -top "${xy#*,}" -width "${wh%x*}" -height "${wh#*x}")
  fi
  xwd -root -display "$display" | xwdtopnm 2>/dev/null | "${crop[@]}" | pnmtopng > "$out" \
    || die "capture failed on display $display"
fi

wl-copy -t image/png < "$out"
echo "screenshot: $out" >&2
