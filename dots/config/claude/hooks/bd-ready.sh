#!/usr/bin/env bash
#
# bd-ready.sh - UserPromptSubmit hook making the tracker ambient; a CLAUDE.md line
# is read once at kickoff. Runs on every prompt, so it must never fail one.
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
