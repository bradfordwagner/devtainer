#!/usr/bin/env bash
# Check Mermaid diagrams: parse them, and optionally render them in a browser.
#
#   mermaid-validate.sh deploy-plan.html            # parse every .mermaid block
#   mermaid-validate.sh --render deploy-plan.html   # + really render it over file://
#   mermaid-validate.sh --offline deploy-plan.html  # render with the network cut
#   mermaid-validate.sh a.html b.mmd                # several at once
#   cat <<'EOF' | mermaid-validate.sh -             # a bare diagram on stdin
#   graph TD
#     A --> B
#   EOF
#
# Written for bw-deployment-planner, whose output is a self-contained HTML page
# with the diagram in a <pre class="mermaid"> that only renders once a browser
# runs it -- so a broken diagram is invisible at write time and reaches the user
# as an empty box.
#
# The two modes catch different failures, and the parse alone is not enough:
#
#   parse (default)  -- the grammar. Fast (~1s), no browser. Catches unquoted
#                       labels, reserved-word ids, empty edge labels.
#   --render         -- a real headless Chromium opening the file over file://.
#                       Catches everything the grammar cannot: a mermaid <script>
#                       that 404s or is missing, a duplicate node id (parses
#                       clean, renders as mermaid's error card), an unknown
#                       shape, a diagram that comes out zero-height. file:// is
#                       the point -- it is how the plan is opened, and it is
#                       stricter than http://, since a module import of a
#                       sibling file is blocked as cross-origin.
#   --offline        -- --render with every non-file:// request aborted, so a
#                       page that only works while jsdelivr is reachable fails
#                       here. Use when the plan must survive a plane or a VPN.
#
# Parse mode reads the file the way the browser does: jsdom parses the HTML and
# the diagram is taken from the element's innerHTML, then run through mermaid's
# own entityDecode + dedent, exactly as mermaid.run() does. Skipping that would
# flag every diagram containing `-->`, since innerHTML re-serialises `>` as
# `&gt;`.
#
# mermaid ships browser-only (its DOMPurify reads `window` at import time), so
# parse mode needs jsdom; --render additionally needs playwright-core and a
# headless Chromium (~275M). Both install on demand into a cache dir outside the
# repo, nothing is vendored, and the Chromium is only fetched if --render is
# actually used. First run of each mode pays the download; after that parse is
# ~1s and render ~2s.

set -uo pipefail

CACHE="${MERMAID_VALIDATE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/mermaid-validate}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

render=0
offline=0
args=()
for a in "$@"; do
  case "$a" in
    --render)  render=1 ;;
    --offline) render=1; offline=1 ;;
    -h|--help) usage; exit 0 ;;
    --*)       echo "mermaid-validate: unknown flag $a" >&2; usage >&2; exit 2 ;;
    *)         args+=("$a") ;;
  esac
done

[ ${#args[@]} -eq 0 ] && { usage >&2; exit 2; }

command -v node >/dev/null || { echo "mermaid-validate: node not on PATH" >&2; exit 2; }
command -v npm  >/dev/null || { echo "mermaid-validate: npm not on PATH" >&2; exit 2; }

ensure() {  # ensure <dirname> <npm-spec>...
  local probe="$1"; shift
  [ -d "$CACHE/node_modules/$probe" ] && return 0
  echo "mermaid-validate: installing $* into $CACHE (one time)" >&2
  mkdir -p "$CACHE" || return 1
  ( cd "$CACHE" && npm install --silent --no-audit --no-fund --omit=dev "$@" >/dev/null 2>&1 )
}

ensure mermaid mermaid@11 jsdom || { echo "mermaid-validate: npm install failed in $CACHE" >&2; exit 2; }

if [ "$render" = 1 ]; then
  export PLAYWRIGHT_BROWSERS_PATH="$CACHE/browsers"
  ensure playwright-core playwright-core || { echo "mermaid-validate: npm install failed in $CACHE" >&2; exit 2; }
  # chromium-headless-shell, not full chromium: ~135M smaller and it is all a
  # headless render needs.
  if [ ! -d "$CACHE/browsers" ] || [ -z "$(ls -A "$CACHE/browsers" 2>/dev/null)" ]; then
    echo "mermaid-validate: downloading headless chromium into $CACHE/browsers (one time, ~275M)" >&2
    if ! ( cd "$CACHE" && npx --yes playwright@latest install chromium-headless-shell >/dev/null 2>&1 ); then
      echo "mermaid-validate: chromium download failed -- parse-only checking still works" >&2
      exit 2
    fi
  fi
fi

# stdin -> temp file, so the payloads only ever deal in paths. Labelled so the
# report says <stdin> rather than a temp name.
tmp=""
paths=()
for a in "${args[@]}"; do
  if [ "$a" = "-" ]; then
    tmp="$(mktemp -t mermaid-validate.XXXXXX.mmd)" || exit 2
    cat > "$tmp"
    paths+=("<stdin>=$tmp")
  else
    [ -r "$a" ] || { echo "mermaid-validate: cannot read $a" >&2; exit 2; }
    paths+=("$a")
  fi
done
[ -n "$tmp" ] && trap 'rm -f "$tmp"' EXIT

export MERMAID_VALIDATE_MODULES="$CACHE/node_modules"

node "$HERE/mermaid-validate.mjs" "${paths[@]}"
rc=$?

if [ "$render" = 1 ]; then
  # Rendering a bare .mmd needs a page to put it in; only HTML is renderable.
  html=()
  for p in "${paths[@]}"; do
    case "${p##*=}" in
      *.html|*.htm) html+=("$p") ;;
      *) echo "note  ${p%%=*}: not HTML, parse-checked only" >&2 ;;
    esac
  done
  if [ ${#html[@]} -gt 0 ]; then
    echo
    MERMAID_VALIDATE_OFFLINE="$offline" node "$HERE/mermaid-render.mjs" "${html[@]}"
    rrc=$?
    [ "$rrc" -gt "$rc" ] && rc=$rrc
  fi
fi

exit $rc
