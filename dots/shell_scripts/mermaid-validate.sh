#!/usr/bin/env bash
# Parse-check Mermaid diagrams, exit non-zero if any is malformed.
#
#   mermaid-validate.sh deploy-plan.html      # every .mermaid block in the file
#   mermaid-validate.sh a.html b.mmd          # several at once
#   cat <<'EOF' | mermaid-validate.sh -       # a bare diagram on stdin
#   graph TD
#     A --> B
#   EOF
#
# Written for bw-deployment-planner, whose output is a self-contained HTML page
# with the diagram in a <pre class="mermaid"> that only renders once a browser
# runs it -- so a syntax error is invisible at write time and shows up as an
# empty box later. This runs the same grammar headlessly and prints the parse
# error with a numbered source listing.
#
# Files are read the way the browser reads them: jsdom parses the HTML, and the
# diagram is taken from the element's innerHTML, exactly as mermaid.run() does.
# That matters -- HTML entities are already decoded and markup normalised by
# then, so a regex scrape of the <pre> would check text mermaid never sees.
#
# mermaid ships browser-only, so this needs jsdom (its DOMPurify reads `window`
# at import time). ~180M of node_modules, installed once into a cache dir
# outside the repo, not vendored. First run pays the npm install; later runs
# are ~0.5s.

set -uo pipefail

CACHE="${MERMAID_VALIDATE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/mermaid-validate}"
PAYLOAD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mermaid-validate.mjs"

if [ $# -eq 0 ]; then
  sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 2
fi

command -v node >/dev/null || { echo "mermaid-validate: node not on PATH" >&2; exit 2; }
command -v npm  >/dev/null || { echo "mermaid-validate: npm not on PATH" >&2; exit 2; }

if [ ! -d "$CACHE/node_modules/mermaid" ] || [ ! -d "$CACHE/node_modules/jsdom" ]; then
  echo "mermaid-validate: installing mermaid + jsdom into $CACHE (one time)" >&2
  mkdir -p "$CACHE" || exit 2
  if ! ( cd "$CACHE" && npm install --silent --no-audit --no-fund --omit=dev \
           mermaid@11 jsdom >/dev/null 2>&1 ); then
    echo "mermaid-validate: npm install failed in $CACHE" >&2
    exit 2
  fi
fi

# stdin -> temp file, so the payload only ever deals in paths.
tmp=""
args=()
for a in "$@"; do
  if [ "$a" = "-" ]; then
    tmp="$(mktemp -t mermaid-validate.XXXXXX.mmd)" || exit 2
    cat > "$tmp"
    args+=("<stdin>=$tmp")
  else
    [ -r "$a" ] || { echo "mermaid-validate: cannot read $a" >&2; exit 2; }
    args+=("$a")
  fi
done
[ -n "$tmp" ] && trap 'rm -f "$tmp"' EXIT

MERMAID_VALIDATE_MODULES="$CACHE/node_modules" node "$PAYLOAD" "${args[@]}"
