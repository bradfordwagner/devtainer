Review this session. Propose minimal edits to:
- The project's `CLAUDE.md` (new conventions, commands, gotchas I corrected you on)
- Subagent definitions (delegation that failed or should have happened). In the dotfiles repo edit `dots/config/claude/agents/*` and never `~/.claude/agents/*`; elsewhere edit `.claude/agents/*`.

Rules:
- Only record lessons from real corrections or failures in this session. Skip anything derivable from the code or git history.
- Prefer editing or removing an existing line over adding one. Remove stale lines.
- Size caps, measured on the diff: net growth of `CLAUDE.md` at most +5 lines per run; each added line one sentence, 200 characters max; no new headings or tables; at most 3 lessons per run. Pick the highest-impact lessons and drop the rest.
- If a lesson needs more than one line, put the depth in a detail doc and leave a one-line pointer in `CLAUDE.md`.
- Apply the edits, then show `git diff` for them. Do not commit.
