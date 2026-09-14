#!/usr/bin/env node
// Existing hand-written deploy-plan.{md,html} -> deploy-plan.yaml + steps/<ID>.md
//
//   deploy-plan-extract.mjs [--dir .] [--write]
//
// One-time migration, run once per session directory. Dry-run by default:
// prints what it would write and what it could not determine. --write commits.
//
// WHAT IT DOES NOT DO: rewrite prose. Step bodies are sliced out of the .md
// verbatim into steps/<ID>.md. The point of the migration is to lift the
// MECHANICAL fields (status, deps, titles) out of prose so they stop being
// hand-maintained in three places -- not to re-author the reasoning, which is
// the part worth keeping exactly as written.
//
// Everything it infers is reported with its source so a wrong guess is visible
// rather than silently baked in. Anything it cannot determine is left absent
// and listed under "needs attention" -- never defaulted to a plausible value.

import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { emitYaml } from './deploy-plan-model.mjs';

const argv = process.argv.slice(2);
let dir = '.', write = false;
for (let i = 0; i < argv.length; i++) {
  if (argv[i] === '--dir') dir = argv[++i];
  else if (argv[i] === '--write') write = true;
  else if (argv[i] === '-h' || argv[i] === '--help') {
    console.log('usage: deploy-plan-extract.mjs [--dir DIR] [--write]');
    process.exit(0);
  } else dir = argv[i];
}
dir = resolve(dir);
const mdPath = join(dir, 'deploy-plan.md');
const htmlPath = join(dir, 'deploy-plan.html');
if (!existsSync(mdPath)) { console.error(`deploy-plan-extract: no deploy-plan.md in ${dir}`); process.exit(2); }

const md = readFileSync(mdPath, 'utf8');
const html = existsSync(htmlPath) ? readFileSync(htmlPath, 'utf8') : '';
const notes = [];   // things a human must check

// ------------------------------------------------------- status, two sources
// The .md checkbox and the .html `class X,Y done` line are independent
// hand-maintained encodings of the same fact. Read BOTH and report every
// disagreement rather than silently preferring one -- a mismatch means one of
// the two files was already stale, which is exactly what this migration ends.

const mdStatus = new Map();
for (const m of md.matchAll(/^- \[([ xX])\]\s*([A-Z]\d+)\s*—?\s*(.*)$/gm)) {
  mdStatus.set(m[2], { done: m[1].toLowerCase() === 'x', line: m[3].trim() });
}

const htmlStatus = new Map();
for (const m of html.matchAll(/^\s*class\s+([A-Z0-9,]+)\s+(done|active|pending|blocked|failed)\s*$/gm)) {
  for (const id of m[1].split(',')) if (/^[A-Z]\d+$/.test(id)) htmlStatus.set(id, m[2]);
}

// -------------------------------------------------------------- step bodies
// Sections are "### <ID> — <title>" in the .md. Slice each to the next "### ".
const sections = [];
const secRe = /^### ([A-Z]\d+)\s*—\s*(.+)$/gm;
let match, prev = null;
while ((match = secRe.exec(md)) !== null) {
  if (prev) prev.end = match.index;
  prev = { id: match[1], title: match[2].trim(), start: secRe.lastIndex, end: md.length };
  sections.push(prev);
}

const ids = [...new Set([...sections.map((s) => s.id), ...mdStatus.keys(), ...htmlStatus.keys()])]
  .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

// ------------------------------------------------------------- dependencies
// Prefer the HTML's Mermaid edges: they are the structured encoding. The .md's
// "**Depends on:** A2 — hard blocker" prose is the fallback, and is only ever
// used to ADD edges the diagram lacks, never to contradict it.
const edges = new Map();  // to -> [{on, kind}]
const addEdge = (from, to, kind) => {
  if (!/^[A-Z]\d+$/.test(from) || !/^[A-Z]\d+$/.test(to)) return;
  if (!edges.has(to)) edges.set(to, []);
  if (!edges.get(to).some((e) => e.on === from)) edges.get(to).push({ on: from, kind: kind || null });
};
for (const m of html.matchAll(/^\s*([A-Z]\d+)\s*-->\s*(?:\|([^|]*)\|)?\s*([A-Z]\d+)/gm)) {
  addEdge(m[1], m[3], m[2] ? m[2].trim() : null);
}
const edgesFromDiagram = [...edges.values()].reduce((n, v) => n + v.length, 0);

for (const sec of sections) {
  const body = md.slice(sec.start, sec.end);
  const dep = body.match(/\*\*Depends on:\*\*\s*([^\n]*(?:\n(?!\*\*)[^\n]*)*)/);
  if (!dep) continue;
  const text = dep[1];

  // "Depends on: none (independent of A1/A2)" and "Not gated on D1/D2" both
  // MENTION step ids while asserting the opposite. A bare id-scrape reads those
  // as dependencies and inverts the clause -- measured on a real plan, where it
  // invented 8 edges from 4 such sentences. So: bail on a leading "none", and
  // drop ids that sit inside an explicitly negating clause.
  const firstLine = text.split('\n')[0];
  if (/^\s*none\b/i.test(firstLine)) continue;

  // A "Depends on:" clause routinely goes on to describe DOWNSTREAM steps --
  // "later stages E1/F1 assume everything is already there". Scraping those
  // yields a REVERSED edge, which on a real plan produced a D1->E1->D1 cycle
  // that the renderer then refused. Ids after a forward-looking marker are not
  // dependencies; cut the text there.
  // The dependency LIST is always the leading fragment; everything from the
  // first parenthesis or em-dash onward is explanation, and explanation names
  // other steps for reasons that are not dependencies:
  //   "D1 Healthy (sync-wave ... C2's config (promoted in F1) ...)"  -> D1 only
  //   "B1, B2 merged; B4/C2/C3 all merged (D1 is gated on ...)"      -> the list
  //   "A2 — hard blocker (merge-before-sync)"                        -> A2 only
  // Scraping the explanation produced a reversed D1->E1 edge and a D1->E1->D1
  // cycle on a real plan. Cutting at the first "(" or em-dash fixes every case
  // observed across three sessions; anything subtler belongs to the human.
  const cut = text.search(/[(—]/);
  const depText = cut >= 0 ? text.slice(0, cut) : text;
  const dropped = cut >= 0 ? [...new Set([...text.slice(cut).matchAll(/\b([A-Z]\d+)\b/g)].map((x) => x[1]))] : [];
  if (dropped.length) {
    notes.push(`${sec.id}: ids mentioned only in the explanatory tail were NOT taken as deps (${dropped.join(', ')}) -- confirm none was a real dependency.`);
  }

  // "**B5**, not A3" negates only what FOLLOWS "not", so the span must start at
  // the negator -- an earlier `[^.;]*` prefix would have swallowed B5 too.
  const NEG = /\b(?:not|never|independent(?:ly)? of|no longer|rather than|instead of|unlike)\b[^.;]*/gi;
  const negSpans = [...depText.matchAll(NEG)].map((m) => [m.index, m.index + m[0].length]);
  const negated = (i) => negSpans.some(([a, b]) => i >= a && i < b);

  const before = (edges.get(sec.id) ?? []).length;
  let skipped = 0;
  for (const m of depText.matchAll(/\b([A-Z]\d+)\b/g)) {
    if (negated(m.index)) { skipped++; continue; }
    // Prose routinely names its own step ("...which is what C1 needs"); a
    // self-edge is always a scrape artefact, never a real dependency.
    if (m[1] === sec.id) { skipped++; continue; }
    addEdge(m[1], sec.id, null);
  }
  const after = (edges.get(sec.id) ?? []).length;
  if (after > before) {
    notes.push(`${sec.id}: ${after - before} dep(s) found only in prose, not in the diagram -- verify they are real: ${firstLine.slice(0, 90)}`);
  }
  if (skipped) {
    notes.push(`${sec.id}: ignored ${skipped} step id(s) inside a negating clause ("not gated on", "independent of", ...) -- confirm none was a real dependency.`);
  }
}

// ------------------------------------------------------------------- fields
const grab = (body, label) => {
  const m = body.match(new RegExp(`\\*\\*${label}:?\\*\\*\\s*([^\\n]*(?:\\n(?!\\*\\*|###)[^\\n]*)*)`));
  return m ? m[1].trim().replace(/\s*\n\s*/g, ' ') : null;
};
const grabFence = (body, label) => {
  // "**Command:**\n```\n...\n```" -- keep the fenced block verbatim.
  const m = body.match(new RegExp(`\\*\\*${label}:?\\*\\*[^\\n]*\\n+\`\`\`[a-z]*\\n([\\s\\S]*?)\`\`\``));
  return m ? m[1].trim() : null;
};

const steps = [];
for (const id of ids) {
  const sec = sections.find((s) => s.id === id);
  const body = sec ? md.slice(sec.start, sec.end) : '';
  const h = htmlStatus.get(id);
  const m = mdStatus.get(id);

  let status = null;
  if (h && m) {
    const agree = (h === 'done') === m.done;
    status = h;
    if (!agree) notes.push(`${id}: STATUS DISAGREEMENT -- .html says "${h}", .md checkbox says ${m.done ? 'done' : 'not done'}. Took the .html. Verify.`);
  } else if (h) status = h;
  else if (m) status = m.done ? 'done' : 'pending';
  else { status = 'pending'; notes.push(`${id}: no status in either file; defaulted to pending -- verify.`); }

  const step = { id, wave: id[0], title: sec ? sec.title : (m ? m.line.replace(/\s*—.*$/, '') : id), status };

  // A done step's body mentions SEVERAL hashes -- the squash commit, its
  // parent, the pre-merge head, drift commits. A lookahead for "squash|merged"
  // grabs whichever comes first on such a line, which on a real plan picked the
  // PARENT out of "tip ca834d61 parents=[a426071f]". Only take a hash that the
  // text explicitly labels, and prefer the longest match (full SHA over the
  // abbreviation of the same commit).
  const labelled = [...body.matchAll(/(?:squash(?:ed)?(?:\s+SHA)?|merge(?:d)?\s+(?:SHA|commit|as))\D{0,16}?\b([0-9a-f]{7,40})\b/gi)]
    .map((m) => m[1]);
  if (labelled.length) {
    step.sha = labelled.sort((a, b) => b.length - a.length)[0];
    if (new Set(labelled.map((h) => h.slice(0, 7))).size > 1) {
      notes.push(`${id}: body labels more than one commit as merged/squashed (${[...new Set(labelled)].join(', ')}); took ${step.sha} -- verify.`);
    }
  }

  const cmd = grabFence(body, 'Command');
  if (cmd) step.command = cmd;
  const gate = grab(body, 'Gate');
  if (gate) step.gate = gate;
  const rev = grab(body, 'Reversible\\?');
  if (rev) step.reversible = rev;
  const tgt = grab(body, 'Target');
  if (tgt) step.target = tgt;

  const deps = edges.get(id);
  if (deps && deps.length) step.depends_on = deps.map((d) => (d.kind ? { on: d.on, kind: d.kind } : d.on));

  // Watch URLs: only keep one if the source actually contains it. Never build
  // a URL from a pattern -- a 404 in a plan is worse than an absent link.
  const pr = body.match(/github\.com\/([\w.-]+\/[\w.-]+)\/pull\/(\d+)/);
  const run = body.match(/github\.com\/([\w.-]+\/[\w.-]+)\/actions\/runs\/(\d+)/);
  if (pr) step.watch = { url: `https://github.com/${pr[1]}/pull/${pr[2]}` };
  else if (run) step.watch = { url: `https://github.com/${run[1]}/actions/runs/${run[2]}` };

  // A section carrying two of the same field means content for a DIFFERENT
  // concern was appended into this step's slice (observed: a shared merge-unit
  // block landing inside the last step of the unit). The extractor takes the
  // first, which may be the wrong one -- so say so rather than pick silently.
  for (const [rx, label] of [['Depends on','Depends on'], ['Command','Command'], ['Gate','Gate'], ['Reversible\\?','Reversible?'], ['Target','Target']]) {
    const n = (body.match(new RegExp(`\\*\\*${rx}:?\\*\\*`, 'g')) ?? []).length;
    if (n > 1) notes.push(`${id}: body has ${n} "**${label}:**" lines -- content for another concern may have been appended into this section. Took the first.`);
  }

  if (sec) step.body = `steps/${id}.md`;
  else notes.push(`${id}: appears in a status list but has no "### ${id} — ..." section; no body extracted.`);

  steps.push(step);
}

// --------------------------------------------------------------------- meta
const title = (md.match(/^#\s+(.+)$/m) || [])[1]
  || (html.match(/<title>([^<]*)<\/title>/) || [])[1]
  || 'Deployment plan';

const repos = {};
for (const m of md.matchAll(/github\.com\/([\w.-]+)\/([\w.-]+)\//g)) {
  const short = m[2].replace(/\.git$/, '');
  repos[short] = `${m[1]}/${short}`;
}

// The Legend table is the one part of the .md preamble that is neither
// derivable nor step-scoped -- it maps short aliases to real cluster/repo
// identifiers, which is exactly the thing that must not be guessed at. Lift it
// verbatim into meta.legend rather than dropping it on the floor.
const legend = {};
const legendBlock = md.match(/^##\s*Legend\s*$([\s\S]*?)(?=^##\s|\Z)/m);
if (legendBlock) {
  for (const row of legendBlock[1].matchAll(/^\|\s*([^|]+?)\s*\|\s*(.+?)\s*\|\s*$/gm)) {
    const [k, v] = [row[1].trim(), row[2].trim()];
    if (!k || /^-+$/.test(k) || /^alias$/i.test(k)) continue;   // separator / header row
    legend[k.replace(/`/g, '')] = v;
  }
}

const meta = { title: title.trim(), repos };
if (Object.keys(legend).length) meta.legend = legend;
const plan = { meta, steps };

// -------------------------------------------------------------------- output
const yamlPath = join(dir, 'deploy-plan.yaml');
const yaml = '# Generated by deploy-plan-extract.mjs from the hand-written\n'
           + '# deploy-plan.{md,html}. Review before trusting: see the notes the\n'
           + '# extractor printed, especially any STATUS DISAGREEMENT lines.\n'
           + emitYaml(plan);

console.log(`steps found:      ${steps.length}`);
console.log(`edges (diagram):  ${edgesFromDiagram}`);
console.log(`edges (total):    ${[...edges.values()].reduce((n, v) => n + v.length, 0)}`);
console.log(`bodies to write:  ${sections.length}`);
console.log(`status: ${['done', 'active', 'pending', 'blocked', 'failed']
  .map((s) => `${steps.filter((x) => x.status === s).length} ${s}`).filter((s) => !s.startsWith('0 ')).join(', ')}`);

if (notes.length) {
  console.log(`\nneeds attention (${notes.length}):`);
  notes.forEach((n) => console.log(`  - ${n}`));
} else {
  console.log('\nneeds attention: none');
}

if (!write) {
  console.log(`\ndry run -- nothing written. Re-run with --write to create:`);
  console.log(`  ${yamlPath}`);
  console.log(`  ${join(dir, 'steps')}/<ID>.md  x${sections.length}`);
  process.exit(0);
}

mkdirSync(join(dir, 'steps'), { recursive: true });
for (const sec of sections) {
  writeFileSync(join(dir, 'steps', `${sec.id}.md`), md.slice(sec.start, sec.end).trim() + '\n');
}
writeFileSync(yamlPath, yaml);
console.log(`\nwrote ${yamlPath} and ${sections.length} body file(s) under ${join(dir, 'steps')}`);
console.log('The original deploy-plan.{md,html} are UNTOUCHED -- keep them until a render satisfies you.');
