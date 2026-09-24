Split a tmux pane and keep a live progress dashboard in it for whatever task is currently running. The argument describes what to track (e.g. `the CI runs for these PRs`, `the test suite`, `the 12 repos we're migrating`); with no argument, infer it from what we're doing in this session.

The pane is for the human to watch while I keep working. It is never something I read back — I get status from my own tool calls.

## When to use this

Worth a pane when the task has **many units or a long wait**: a fleet of CI runs, a multi-repo change, a long build, a batch of files, a queue draining. Not worth it for a task with two quick steps — just narrate those inline.

If `$TMUX` is unset, skip silently and narrate progress inline instead. Say so once; don't retry.

## Two modes — pick one

**Probe mode** — each row owns a shell command that reports its own state. Use when the truth lives somewhere queryable (GitHub Actions, a URL, a file, a process). The pane stays current on its own, and I don't have to touch it.

**Step mode** — I own a state file and rewrite it as work progresses. Use when progress only exists in my head (phases of a migration, items in a batch I'm working through). Costs me a file write per transition.

When both fit, prefer probe mode; it can't go stale.

## Setup (both modes)

Put everything in the scratchpad directory, never in the project.

1. Anchor to **this session's own pane**, via the `$TMUX_PANE` env var my shell inherits:
   ```bash
   TARGET="${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}"
   ```
   Do **not** use a bare `tmux display-message -p ...` as the target. That resolves whatever pane is *active at the moment the command runs* — so if the user switches window or pane after sending their message (they often do), the split lands in whatever they navigated to. `$TMUX_PANE` is the pane Claude is actually running in and doesn't move. Only fall back to `display-message` if `$TMUX_PANE` is somehow unset.
2. Split that pane specifically, and capture the new pane id in the same step:
   `NEWPANE=$(tmux split-window -t "$TARGET" -h -l 54 -P -F '#{pane_id}')`
   The new pane lands in the same window as the session, regardless of where the user is looking.
3. Write the state file and the renderer (below).
4. Launch it: `tmux send-keys -t "$NEWPANE" "bash <scratchpad>/pane.sh" Enter`
5. Confirm it rendered once: `tmux capture-pane -t "$NEWPANE" -p | head -20`. If it's empty or broken, fix it now — a wrong pane is worse than no pane.
6. Remember `$NEWPANE` for the rest of the session.

At the end: `tmux send-keys -t "$NEWPANE" C-c` to stop the refresh loop but **leave the final state on screen**. Don't kill the pane; the user wants to read it.

## State file contract

One row per tracked thing, tab-separated, in the scratchpad. Lines starting `#` are group headings. Keep it small enough to rewrite wholesale rather than edit in place.

Probe mode — `label<TAB>command`:
```
# containers
devtainer	cd /path/repo && gh run list --branch my-branch --limit 1 --json status,conclusion --jq '.[0]|"\(.status) \(.conclusion // "-")"'
```

Step mode — `label<TAB>status<TAB>detail<TAB>start_epoch<TAB>end_epoch`:
```
clone repos	done	14 repos	1727054400	1727054460
run migration	active	7/14	1727054460	0
verify	pending		0	0
```
`status` is one of `pending|active|done|failed`. Epochs are `0` until set.

## Renderer

Plain bash only — it runs unattended, so **no `jq` dependency** (use `gh --jq`, `awk`, or `python3`). Redraw on a `clear`, `sleep 5`-`10` between passes.

```bash
#!/usr/bin/env bash
STATE="$(dirname "$0")/state.tsv"
START=$(date +%s); SPIN='|/-\'; i=0
hms() { printf '%02d:%02d' $(($1/60)) $(($1%60)); }

while true; do
  body=""; ok=0; bad=0; run=0; wait=0
  while IFS=$'\t' read -r label a b c d; do
    [ -z "$label" ] && continue
    case "$label" in \#*) body+=$(printf '\n \033[36m%s\033[0m' "${label#\# }")$'\n'; continue ;; esac

    # probe mode: $a is a command. step mode: $a is already a status.
    case "$a" in
      pending|active|done|failed) st=$a; detail=$b ;;
      *) st=$(eval "$a" 2>/dev/null); detail="" ;;
    esac
    # a probe for something that doesn't exist yet returns empty, or a jq
    # "null ..." string. That is pending -- never let it fall through to the
    # spinner, which reads as a hang. Use `case`, not `[ -z ] || [ = ] && ...`:
    # that chain has the wrong precedence and silently misfires.
    case "$st" in ''|null*|'-') st="pending" ;; esac

    case "$st" in
      done|*success*)   g='+'; c=$'\033[32m'; ok=$((ok+1)) ;;
      failed|*failure*) g='x'; c=$'\033[31m'; bad=$((bad+1)) ;;
      pending|queued*)  g='.'; c=$'\033[90m'; wait=$((wait+1)) ;;
      *)                g="${SPIN:$((i%4)):1}"; c=$'\033[33m'; run=$((run+1)) ;;
    esac
    body+=$(printf ' %s%s %-24s %s\033[0m' "$c" "$g" "${label:0:24}" "${detail:0:16}")$'\n'
  done < "$STATE"

  clear
  printf '\033[1m %s\033[0m %s  \033[32m%dok\033[0m \033[31m%dfail\033[0m \033[33m%drun\033[0m \033[90m%dwait\033[0m\n' \
    "TASK NAME" "$(hms $(($(date +%s)-START)))" "$ok" "$bad" "$run" "$wait"
  printf '%s' "$body"
  printf '\n \033[90mctrl-c to stop\033[0m\n'
  i=$((i+1)); sleep 8
done
```

Adapt freely — add a `[####....]` bar when rows have a done/total, drop the counters when there are only three rows. The structure matters more than the styling.

## Rules learned the hard way

- **Capture the pane id, never assume it.** Panes get closed; `tmux send-keys` then fails with `can't find pane: %24`. If that happens, re-split from `$TMUX_PANE` and relaunch rather than giving up.
- **Address every later call by pane id (`%N`), never by `session:window.pane`.** Index-style targets shift when panes or windows are added, closed, or reordered; a `%N` id is stable for the life of the pane. This also means the dashboard keeps updating correctly while the user is off in another window.
- **Fit the width.** At `-l 54` a header like `rollout  elapsed 03:21  0 ok 0 fail 19 running` wraps and looks broken. Short labels, truncate with `${var:0:24}`, abbreviate counters (`3ok` not `3 running jobs`).
- **A row with nothing yet must say so.** Guard against empty/`null` query results and print `pending` — a spinner on a thing that doesn't exist yet reads as a hang.
- **Never dump CI logs into the pane.** One line per unit. Details belong in my tool calls, not on the user's screen.
- **tmux may be blocked.** If a `tmux` call is denied by permissions, say so once and fall back to inline narration. Don't work around it.
- **Don't poll in my own context to feed the pane.** The pane polls itself in probe mode; in step mode I write the file only when something actually changes.

## Reporting

The pane supplements my updates, it doesn't replace them. I still say what changed, when it changed, in the conversation. When the task finishes: freeze the pane, then give the summary in chat — the user shouldn't have to read the pane to know the outcome.

If durations matter to the user, the epochs in step mode (or a run's `createdAt`/`updatedAt` in probe mode) are enough to report per-item time, total wall-clock, and the slowest item at the end.
