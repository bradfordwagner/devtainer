#!/usr/bin/env bash
#
# bd-ready.sh - UserPromptSubmit hook: put the session's issue tracker in front
# of the model on every turn.
#
# Why a hook rather than another line in the session CLAUDE.md: "ask `bd ready`
# before planning" reads as a one-time act at kickoff, and that is exactly how it
# gets followed -- beads filed at the start, closed in a batch at the end, and
# nothing in between reflecting the scope that arrived mid-session. More prose
# does not fix that; the doc was already in context. Making the tracker ambient
# does: a stale tracker becomes visible every turn instead of invisible until
# someone asks "what's left".
#
# Silent outside a session -- no beads database, no output, no failure. This runs
# on every prompt, so it must never be the reason one fails.
set -uo pipefail

command -v bd >/dev/null 2>&1 || exit 0

ready=$(bd ready 2>/dev/null) || exit 0
case "${ready}" in '' | *'no beads database'* | *'Error:'*) exit 0 ;; esac

# keep the issue lines, drop bd's rules, counts and legend
issues() { grep -vE '^[[:space:]]*$|^-+$|^Ready:|^Status:|^Total:|^No issues|^✨' || true; }

active=$(bd list --status in_progress 2>/dev/null | issues)
open=$(issues <<<"${ready}" | head -10)

printf '<session-beads>\n'
[[ -n ${active} ]] && printf 'in progress:\n%s\n' "${active}" || printf 'in progress: none\n'
if [[ -n ${open} ]]; then
  printf 'ready:\n%s\n' "${open}"
else
  # the state most worth noticing right after a batch of work lands
  printf 'ready: none -- any work still in flight is untracked\n'
fi
printf '</session-beads>\n'
