#!/usr/bin/env bash
# Tally token usage and cost for one Claude Code session transcript.
#
# Exists because the transcript records usage but never cost, and because a
# naive tally double-counts: a single assistant turn is written to the JSONL
# once per content block, each copy carrying the *same* cumulative usage. So we
# dedupe on message.id -- see the accountant agent prompt for why that matters.
#
# Usage: session-usage.sh [--session ID] [--project DIR] [--json]
# Default session is $CLAUDE_CODE_SESSION_ID (the live session).
# Exit 2 = cannot run (no jq, no transcript); exit 1 = bad usage.

set -uo pipefail

session="${CLAUDE_CODE_SESSION_ID:-}"
project=""
fmt="text"

while [ $# -gt 0 ]; do
  case "$1" in
    --session) session="${2:-}"; shift 2 ;;
    --project) project="${2:-}"; shift 2 ;;
    --json)    fmt="json"; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "session-usage: jq not found" >&2; exit 2; }

if [ -z "$session" ]; then
  echo "session-usage: no session id (pass --session, or run inside Claude Code)" >&2
  exit 2
fi

# Claude Code slugifies the *session's* cwd to name the project dir -- which is
# not necessarily this shell's cwd, so try that first and then fall back to a
# search. A cd into a subdir would otherwise make the transcript look missing.
if [ -z "$project" ]; then
  guess="$HOME/.claude/projects/$(echo "$PWD" | sed 's|/|-|g')"
  if [ -f "$guess/$session.jsonl" ]; then
    project="$guess"
  else
    hit=$(find "$HOME/.claude/projects" -maxdepth 2 -name "$session.jsonl" 2>/dev/null | head -1)
    [ -n "$hit" ] && project=$(dirname "$hit") || project="$guess"
  fi
fi

main="$project/$session.jsonl"
[ -f "$main" ] || { echo "session-usage: no transcript for session $session" >&2; exit 2; }

# Subagent turns live in a sibling dir and never appear in the main transcript,
# so a tally that reads only the main file silently under-reports delegated work.
subagents="$project/$session/subagents"
files=("$main")
if [ -d "$subagents" ]; then
  while IFS= read -r f; do files+=("$f"); done < <(find "$subagents" -name '*.jsonl' 2>/dev/null)
fi

# Rates in USD per million tokens: input, output, cache-write-5m, cache-write-1h,
# cache-read. Cache write is 1.25x base input for the 5m TTL and 2x for 1h; cache
# read is 0.1x. No long-context premium on current models, so these are flat.
# Update when Anthropic pricing changes -- these are the only numbers here that rot.
cat "${files[@]}" 2>/dev/null | jq -s --arg session "$session" --arg fmt "$fmt" '
  def rates:
    { "claude-opus-5":            {i:5,  o:25, cw5:6.25,  cw1h:10,  cr:0.5},
      "claude-opus-4-8":          {i:5,  o:25, cw5:6.25,  cw1h:10,  cr:0.5},
      "claude-opus-4-7":          {i:5,  o:25, cw5:6.25,  cw1h:10,  cr:0.5},
      "claude-opus-4-6":          {i:5,  o:25, cw5:6.25,  cw1h:10,  cr:0.5},
      "claude-fable-5":           {i:10, o:50, cw5:12.5,  cw1h:20,  cr:1.0},
      "claude-sonnet-5":          {i:3,  o:15, cw5:3.75,  cw1h:6,   cr:0.3},
      "claude-sonnet-4-6":        {i:3,  o:15, cw5:3.75,  cw1h:6,   cr:0.3},
      "claude-haiku-4-5":         {i:1,  o:5,  cw5:1.25,  cw1h:2,   cr:0.1},
      "claude-haiku-4-5-20251001":{i:1,  o:5,  cw5:1.25,  cw1h:2,   cr:0.1}
    };

  # One assistant turn appears once per content block, each copy repeating the
  # same usage. Dedupe on message.id or every multi-block turn is counted twice.
  ( [ .[] | select(.type=="assistant" and .message.id != null) ]
    | group_by(.message.id) | map(.[0]) ) as $turns

  | ( [ $turns[] | select(.message.model != "<synthetic>") ] ) as $real

  # Synthetic turns are harness-generated (cancels, errors) and carry zero usage.
  | ( $turns | length ) as $all_turns
  | ( $real  | length ) as $billable_turns

  | ( $real | group_by(.message.model) | map(
        (.[0].message.model) as $m
      | (rates[$m] // null) as $r
      | ( [ .[].message.usage.input_tokens               ] | add // 0) as $in
      | ( [ .[].message.usage.output_tokens              ] | add // 0) as $out
      | ( [ .[].message.usage.cache_read_input_tokens    ] | add // 0) as $cr
      | ( [ .[].message.usage.cache_creation.ephemeral_5m_input_tokens // 0 ] | add // 0) as $cw5
      | ( [ .[].message.usage.cache_creation.ephemeral_1h_input_tokens // 0 ] | add // 0) as $cw1h
      | ( [ .[].message.usage.output_tokens_details.thinking_tokens // 0 ] | add // 0) as $think
      | { model: $m, turns: length,
          input: $in, output: $out, cache_read: $cr,
          cache_write_5m: $cw5, cache_write_1h: $cw1h, thinking: $think,
          priced: ($r != null),
          cost: (if $r == null then 0 else
                   ($in*$r.i + $out*$r.o + $cr*$r.cr + $cw5*$r.cw5 + $cw1h*$r.cw1h) / 1000000
                 end) }
    ) ) as $by_model

  | ( [ $real[] | select(.isSidechain == true) ] | length ) as $sub_turns
  | ( [ .[] | select(.type=="assistant" or .type=="user") | .timestamp ] | map(select(. != null)) | sort ) as $ts
  | ( [ .[] | select(.type=="user" and .message.role=="user"
        and (.isSidechain != true) and (.isMeta != true)
        and (.toolUseResult == null)
        and ((.message.content | if type=="array"
              then (map(select(.type=="tool_result")) | length) == 0
              else true end))) ] | length ) as $prompts
  | ( [ .[] | select(.aiTitle != null) | .aiTitle ] | last ) as $title
  | ( [ .[] | select(.gitBranch != null) | .gitBranch ] | last ) as $branch
  | ( [ .[] | select(.type=="assistant") | .message.content[]?
        | select(.type=="tool_use") | .name ] ) as $tools

  | { session: $session,
      title: ($title // "untitled"),
      branch: ($branch // "unknown"),
      started: ($ts | first), ended: ($ts | last),
      prompts: $prompts,
      turns: $billable_turns, synthetic_turns: ($all_turns - $billable_turns),
      subagent_turns: $sub_turns,
      tool_calls: ($tools | length),
      top_tools: ($tools | group_by(.) | map({name: .[0], n: length})
                  | sort_by(-.n) | .[0:5]),
      by_model: $by_model,
      totals: { input:  ([$by_model[].input]|add // 0),
                output: ([$by_model[].output]|add // 0),
                cache_read: ([$by_model[].cache_read]|add // 0),
                cache_write: ([$by_model[].cache_write_5m]|add // 0)
                             + ([$by_model[].cache_write_1h]|add // 0),
                thinking: ([$by_model[].thinking]|add // 0),
                cost: ([$by_model[].cost]|add // 0) },
      unpriced_models: [ $by_model[] | select(.priced|not) | .model ] }

  | if $fmt == "json" then . else
      ( "session:  \(.session)"
      + "\ntitle:    \(.title)"
      + "\nbranch:   \(.branch)"
      + "\nwindow:   \(.started) -> \(.ended)"
      + "\nprompts:  \(.prompts)   turns: \(.turns)   subagent turns: \(.subagent_turns)"
      + "\ntools:    \(.tool_calls) calls"
      + "\n"
      + "\ntokens:   in=\(.totals.input)  out=\(.totals.output)"
      + "  cache_read=\(.totals.cache_read)  cache_write=\(.totals.cache_write)"
      + "\nthinking: \(.totals.thinking)"
      + "\ncost:     $\(.totals.cost*10000|round/10000)"
      + "\n\nby model:"
      + ( [ .by_model[] | "\n  \(.model)  turns=\(.turns)  in=\(.input) out=\(.output)"
            + " cr=\(.cache_read) cw=\(.cache_write_5m + .cache_write_1h)"
            + "  $\(.cost*10000|round/10000)"
            + (if .priced then "" else "  [UNPRICED]" end) ] | join("") )
      + (if (.unpriced_models|length) > 0 then
           "\n\nWARNING: no rate for \(.unpriced_models|join(", ")) -- cost understated"
         else "" end) )
    end' --raw-output
