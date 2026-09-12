#!/usr/bin/env bash
# Check that a deployment plan's labels agree with its waves, and that its two
# files agree with each other.
#
#   deploy-plan-lint.sh deploy-plan.html deploy-plan.md
#   deploy-plan-lint.sh deploy-plan.html            # diagram + table only
#
# Written for bw-deployment-planner. Its label scheme -- the letter is the wave,
# the number is the step within it -- is what makes a label self-describing, so
# "run wave A" and "run A1, A2" are the same instruction and the releaser can be
# handed labels rather than prose. The scheme only holds if it holds everywhere,
# and its failure mode is silent: a diagram whose waves are correct and whose
# labels are noise still renders beautifully, so mermaid-validate.sh passes it.
#
# The failure this exists to catch is a specific one. The planner enumerates
# steps as it finds them, letters them A, B, C..., works out the dependencies,
# groups the steps into subgraphs, and never revisits the letters -- landing a
# "Wave A" holding A1, B1 and N1. Every label a `1` is the tell.
#
# What is checked:
#   diagram  every node in `subgraph wX` is labelled X<n>, numbered 1..n in
#            declaration order with no gaps; waves declared A, B, C...; no node
#            conjured by an edge outside every subgraph (an edge declared before
#            its nodes creates them, and they land outside the wave you meant)
#   status   every `class <labels> <state>` line names only real nodes, every
#            node is in exactly one state, and the state is one the plan
#            defines. mermaid ignores a class naming a node that does not
#            exist -- it does not error, the node simply never gets painted --
#            so the releaser can mistype a label, see a clean render, and
#            report progress the diagram is not showing
#   html     one `id="step-<LABEL>"` row per label, same set, same order, each
#            with the data-status handle the releaser edits
#   md       `- [ ] <LABEL> - ...` checkboxes and `### <LABEL>` context sections,
#            same set and order as the diagram, and each `<!-- wave X -->` group
#            holding only X-labels
#
# Exit 0 clean, 1 a bad plan, 2 the tool could not run -- the same convention as
# mermaid-validate.sh, which this is meant to be run alongside: that one checks
# the diagram draws, this one checks it says what it means.

set -uo pipefail

if [[ $# -eq 0 || $1 == -h || $1 == --help ]]; then
  sed -n '2,32p' "$0" | sed 's/^# \?//'
  exit 0
fi

command -v python3 >/dev/null 2>&1 || { echo "deploy-plan-lint: python3 not found" >&2; exit 2; }

for f in "$@"; do
  [[ -r $f ]] || { echo "deploy-plan-lint: cannot read $f" >&2; exit 2; }
done

python3 - "$@" <<'PY'
import re, sys

paths = sys.argv[1:]
html = next((p for p in paths if p.endswith(('.html', '.htm'))), None)
md   = next((p for p in paths if p.endswith('.md')), None)
for p in paths:
    if p not in (html, md):
        sys.stderr.write(f"deploy-plan-lint: {p}: expected a .html or .md plan\n")
        sys.exit(2)

errs, notes = [], []
def err(f, m): errs.append(f"{f}: {m}")

LABEL = re.compile(r'^([A-Z])([0-9]+)$')

diagram_labels = []   # in declaration order, the diagram is the source of truth

if html:
    src = open(html, encoding='utf-8').read()
    blocks = re.findall(r'<pre[^>]*class="[^"]*\bmermaid\b[^"]*"[^>]*>(.*?)</pre>', src, re.S)
    if not blocks:
        err(html, 'no <pre class="mermaid"> diagram found')
    for bi, raw in enumerate(blocks, 1):
        body = raw.replace('&gt;', '>').replace('&lt;', '<').replace('&quot;', '"').replace('&amp;', '&')
        where = html if len(blocks) == 1 else f"{html} (diagram {bi})"

        # walk the source, tracking which subgraph we are inside
        stack, waves, order, seen = [], [], [], {}
        for ln, line in enumerate(body.split('\n'), 1):
            s = line.strip()
            m = re.match(r'^subgraph\s+(\S+?)(?:\[|\s|$)', s)
            if m:
                sg = m.group(1)
                stack.append(sg)
                if len(stack) == 1:
                    wm = re.match(r'^w?([A-Z])$', sg)
                    if not wm:
                        err(where, f'line {ln}: subgraph id "{sg}" is not a wave id '
                                   f'(expected wA, wB, ... -- one per wave)')
                        waves.append((None, sg, []))
                    else:
                        waves.append((wm.group(1), sg, []))
                continue
            if s == 'end' or s.startswith('end '):
                if stack: stack.pop()
                continue
            if s.startswith(('graph ', 'flowchart ', 'classDef', 'class ', 'style ', 'click ', '%%')):
                continue
            # a node declaration: an id immediately followed by a shape opener
            for nm in re.finditer(r'(?:^|[\s;])([A-Za-z][A-Za-z0-9_]*)\s*[\[\(\{]', line):
                nid = nm.group(1)
                if nid in seen: continue
                seen[nid] = ln
                order.append(nid)
                if stack and waves:
                    waves[-1][2].append((nid, ln))
                else:
                    err(where, f'line {ln}: node "{nid}" is declared outside every subgraph '
                               f'-- it belongs to no wave (declare nodes inside their '
                               f'subgraph, edges after the last "end")')

        # nodes an edge conjured into existence, never declared with a shape
        for em in re.finditer(r'(?:^|\n)\s*([A-Za-z][A-Za-z0-9_]*)\s*(?:-{2,3}|-\.|={2,})', body):
            nid = em.group(1)
            if nid not in seen and nid not in ('graph', 'flowchart', 'subgraph', 'end'):
                err(where, f'node "{nid}" appears only in an edge and was never declared '
                           f'in a subgraph -- it will render outside every wave')
        for em in re.finditer(r'(?:-{2,3}>|-\.->|={2,}>)\|?[^|\n]*\|?\s*([A-Za-z][A-Za-z0-9_]*)\s*(?:$|\n|;)', body):
            nid = em.group(1)
            if nid not in seen and nid not in ('graph', 'flowchart', 'subgraph', 'end'):
                err(where, f'node "{nid}" appears only in an edge and was never declared '
                           f'in a subgraph -- it will render outside every wave')

        # THE invariant: subgraph wX holds X1..Xn, in order, no gaps
        for letter, sg, members in waves:
            if letter is None: continue
            wrong = [n for n, _ in members if not (LABEL.match(n) and LABEL.match(n).group(1) == letter)]
            if wrong:
                got = ' '.join(n for n, _ in members)
                want = ' '.join(f'{letter}{i}' for i in range(1, len(members) + 1))
                err(where, f'subgraph {sg} (wave {letter}) contains {", ".join(wrong)} -- '
                           f'every step in wave {letter} must be labelled {letter}<n>.\n'
                           f'    got:  {got}\n'
                           f'    want: {want}')
                if all(LABEL.match(n) and LABEL.match(n).group(2) == '1' for n, _ in members) and len(members) > 1:
                    err(where, f'    (every label in {sg} is a "1" -- these are step letters, '
                               f'not wave letters. Group into waves first, label second.)')
                continue
            nums = [int(LABEL.match(n).group(2)) for n, _ in members]
            if nums != list(range(1, len(nums) + 1)):
                err(where, f'subgraph {sg} is numbered {nums} -- steps in a wave run '
                           f'1, 2, 3... in declaration order, with no gaps')

        # release-status classes: the releaser rewrites these, and a typo is silent
        # Release states only. A plan may also carry decorative classes of its own
        # (a `gate` highlight, say), and a node legitimately holds both: the status
        # classDef is defined last, so it wins the cascade and repaints the node.
        # Only same-node collisions *between two release states* are a real conflict.
        STATES = {'done', 'active', 'failed', 'blocked', 'pending'}
        declared = set(seen)
        classdefs = set(re.findall(r'^\s*classDef\s+(\w+)', body, re.M))
        has_status = bool(re.search(r'release status:.*bw-deployment-releaser', body)) \
                     or bool(STATES & classdefs)
        state_of = {}
        for cm in re.finditer(r'^\s*class\s+([\w,\s]+?)\s+(\w+)\s*$', body, re.M):
            state = cm.group(2)
            members = [x.strip() for x in cm.group(1).split(',') if x.strip()]
            # a node named by any class line must exist, decorative or not
            for n in members:
                if n not in declared:
                    err(where, f'class {n} {state}: no node "{n}" in this diagram. '
                               f'mermaid ignores this silently -- the label you meant '
                               f'stays unpainted and the diagram under-reports progress')
            if state not in STATES:
                if state not in classdefs:
                    err(where, f'class ... {state}: no "classDef {state}" defines it '
                               f'(mermaid applies nothing and says nothing)')
                continue                      # decorative, not a release state
            if state != 'pending' and state not in classdefs:
                err(where, f'class ... {state}: no "classDef {state}" defines it '
                           f'(mermaid applies nothing and says nothing)')
            for n in members:
                if n not in declared:
                    continue                  # already reported above
                if n in state_of and state_of[n] != state:
                    err(where, f'node {n} is in two release states: {state_of[n]} and '
                               f'{state} -- the later line wins, which is unlikely to '
                               f'be what was meant')
                else:
                    state_of[n] = state

        if has_status:
            unpainted = [n for n in order if n not in state_of]
            if unpainted:
                err(where, f'no class line covers {", ".join(unpainted)} -- every label '
                           f'must appear in exactly one state, or its progress is unknown')

        letters = [l for l, _, _ in waves if l]
        if letters != sorted(letters):
            err(where, f'waves are declared {" ".join(letters)} -- declare them in alphabetical '
                       f'order so the diagram reads top-to-bottom as time')
        if len(set(letters)) != len(letters):
            dup = [l for l in set(letters) if letters.count(l) > 1]
            err(where, f'wave letter(s) {", ".join(sorted(dup))} used by more than one subgraph')

        if bi == 1:
            diagram_labels = [n for _, _, ms in waves for n, _ in ms]

    # the wave table the releaser edits
    rows = re.findall(r'id="step-([^"]+)"', src)
    if not rows:
        notes.append(f'{html}: no id="step-<LABEL>" rows found -- the releaser has no handle '
                     f'to mark progress against')
    else:
        if diagram_labels and rows != diagram_labels:
            err(html, f'wave table rows do not match the diagram.\n'
                      f'    table:   {" ".join(rows)}\n'
                      f'    diagram: {" ".join(diagram_labels)}')
        for lbl in rows:
            row = re.search(r'id="step-' + re.escape(lbl) + r'"(.*?)</tr>', src, re.S)
            if row and 'data-status=' not in row.group(1):
                err(html, f'row step-{lbl} has no data-status cell -- the releaser edits that '
                          f'attribute to mark the step done')

if md:
    text = open(md, encoding='utf-8').read()
    lines = text.split('\n')

    boxes, cur_wave, wave_of = [], None, {}
    for ln, line in enumerate(lines, 1):
        wm = re.match(r'^\s*<!--\s*wave\s+([A-Za-z])\s*-->\s*$', line)
        if wm:
            cur_wave = wm.group(1).upper()
            continue
        bm = re.match(r'^- \[( |x|X)\] (\S+)\s+[—-]\s', line)
        if bm:
            lbl = bm.group(2)
            boxes.append(lbl)
            wave_of[lbl] = (cur_wave, ln)
            if re.match(r'^- \[.\] [*\[`]', line):
                err(md, f'line {ln}: label must be bare -- "A1", not "**A1**" or "[A1]"')
            continue
        if re.match(r'^\s*- \[( |x|X)\]', line) and not bm:
            err(md, f'line {ln}: checkbox does not match "- [ ] <LABEL> — <text>":\n    {line.strip()}')

    if not boxes:
        err(md, 'no "- [ ] <LABEL> — <text>" checkbox list found')
    else:
        first_box = next(i for i, l in enumerate(lines, 1) if re.match(r'^- \[( |x|X)\] ', l))
        for ln, line in enumerate(lines[:first_box - 1], 1):
            if line.startswith('##'):
                err(md, f'line {ln}: "{line.strip()}" sits above the checkbox list -- nothing '
                        f'goes above it but the title')

        for lbl, (w, ln) in wave_of.items():
            m = LABEL.match(lbl)
            if not m:
                err(md, f'line {ln}: label "{lbl}" is not <WAVE-LETTER><step-number>')
            elif w is None:
                err(md, f'line {ln}: {lbl} has no "<!-- wave X -->" comment above it')
            elif m.group(1) != w:
                err(md, f'line {ln}: {lbl} sits under "<!-- wave {w} -->" -- a step in wave {w} '
                        f'must be labelled {w}<n>')

        if diagram_labels and boxes != diagram_labels:
            err(md, f'checkbox list does not match the diagram.\n'
                    f'    md:      {" ".join(boxes)}\n'
                    f'    diagram: {" ".join(diagram_labels)}')

        ctx = re.findall(r'^###\s+(\S+?)\s*[—-]', text, re.M)
        if ctx:
            missing = [l for l in boxes if l not in ctx]
            extra   = [l for l in ctx if l not in boxes]
            if missing: err(md, f'no ## Context section for: {", ".join(missing)}')
            if extra:   err(md, f'## Context has sections with no checkbox: {", ".join(extra)}')
            if not missing and not extra and ctx != boxes:
                err(md, f'## Context sections are out of order.\n'
                        f'    context:  {" ".join(ctx)}\n'
                        f'    checklist:{" ".join(boxes)}')
        else:
            notes.append(f'{md}: no "### <LABEL> — ..." context sections found')

for n in notes:
    print(f"note: {n}")
if errs:
    print()
    for e in errs:
        print(f"FAIL {e}")
    print(f"\n{len(errs)} problem(s). The label scheme is load-bearing: a wave whose steps do "
          f"not share its letter\nbreaks 'run wave A' as an instruction. Fix and re-run.")
    sys.exit(1)

print(f"OK  {', '.join(paths)}" + (f" — {len(diagram_labels)} steps, labels consistent" if diagram_labels else ""))
PY
