// Shared model for deploy-plan-render.mjs and deploy-plan-extract.mjs:
// a YAML-subset parser, the schema check, and the derivations both sides need.
//
// WHY A HAND-ROLLED PARSER. The `yaml` package is not installed, and the
// neighbouring mermaid-validate.sh solves that by npm-installing into a cache
// on every run. That is the wrong trade here: the plan schema is small, fixed,
// and machine-written (deploy-plan-extract.mjs emits it), so the input space is
// narrow. What matters is that a construct we do NOT handle fails loudly rather
// than parsing to something plausible-but-wrong -- a misparsed `status` would
// silently repaint the DAG. Hence: a strict subset, and `throw` on anything
// outside it. Do not "improve" this by making it lenient.
//
// The supported subset, in full:
//   key: scalar            nested maps by 2-space indent
//   key:                   list items as "- scalar" or "- key: v" (inline map)
//   # comments, blank lines
//   scalars: bare, 'single', "double", true/false/null/~, integers
// Anything else -- anchors, multi-line scalars, flow maps/sequences, tabs --
// raises. See parseYamlSubset.

export const STATUSES = ['pending', 'active', 'done', 'failed', 'blocked'];

// ---------------------------------------------------------------- YAML subset

function parseScalar(raw) {
  const s = raw.trim();
  if (s === '' ) return '';
  if (s === 'null' || s === '~') return null;
  if (s === 'true') return true;
  if (s === 'false') return false;
  if (/^-?\d+$/.test(s)) return Number(s);
  if ((s.startsWith("'") && s.endsWith("'") && s.length > 1) ||
      (s.startsWith('"') && s.endsWith('"') && s.length > 1)) {
    return s.slice(1, -1);
  }
  // Reject the flow constructs we do not implement, rather than storing them
  // as strings and letting a caller treat "[a, b]" as a one-element list.
  if (s.startsWith('[') || s.startsWith('{')) {
    throw new Error(`flow collections are not supported: ${s}`);
  }
  if (s.startsWith('&') || s.startsWith('*') || s === '|' || s === '>') {
    throw new Error(`unsupported YAML construct: ${s}`);
  }
  return s;
}

function splitKey(line) {
  // Find the ':' that separates key from value, ignoring ones inside quotes.
  let q = null;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (q) { if (c === q) q = null; continue; }
    if (c === "'" || c === '"') { q = c; continue; }
    if (c === ':' && (i + 1 === line.length || line[i + 1] === ' ')) {
      return [line.slice(0, i).trim(), line.slice(i + 1).trim()];
    }
  }
  return null;
}

export function parseYamlSubset(text) {
  const lines = [];
  text.split('\n').forEach((raw, i) => {
    if (raw.includes('\t')) throw new Error(`line ${i + 1}: tabs are not valid YAML indentation`);
    // Strip comments, but NOT inside quotes: titles in this estate routinely
    // carry issue refs ("squash-merge PR #1900"), and a naive /\s#.*$/ truncates
    // the value AND leaves the opening quote unbalanced -- silent corruption
    // that reaches the rendered page as a mangled title.
    let end = raw.length, q = null;
    for (let j = 0; j < raw.length; j++) {
      const c = raw[j];
      if (q) { if (c === q) q = null; continue; }
      if (c === "'" || c === '"') { q = c; continue; }
      if (c === '#' && (j === 0 || /\s/.test(raw[j - 1]))) { end = j; break; }
    }
    const noComment = raw.slice(0, end).replace(/\s+$/, '');
    if (noComment.trim() === '') return;
    lines.push({ n: i + 1, indent: noComment.length - noComment.trimStart().length, text: noComment.trim() });
  });

  let pos = 0;
  function parseBlock(indent) {
    // Decide list-vs-map from the first line at this level, then require the
    // rest to agree -- a mixed block is a typo, not a shape.
    if (pos >= lines.length) return null;
    return lines[pos].text.startsWith('- ') || lines[pos].text === '-'
      ? parseList(indent)
      : parseMap(indent);
  }

  function parseList(indent) {
    const out = [];
    while (pos < lines.length && lines[pos].indent === indent) {
      const line = lines[pos];
      if (!line.text.startsWith('- ')) break;
      const rest = line.text.slice(2).trim();
      pos++;
      const kv = splitKey(rest);
      if (kv) {
        // "- key: value" starts an inline map; its siblings are indented to
        // where `key` began (indent + 2 for the "- ").
        const item = {};
        if (kv[1] === '') {
          const child = pos < lines.length && lines[pos].indent > indent ? parseBlock(lines[pos].indent) : null;
          item[kv[0]] = child;
        } else {
          item[kv[0]] = parseScalar(kv[1]);
        }
        while (pos < lines.length && lines[pos].indent === indent + 2 && !lines[pos].text.startsWith('- ')) {
          const sub = splitKey(lines[pos].text);
          if (!sub) throw new Error(`line ${lines[pos].n}: expected "key: value"`);
          pos++;
          if (sub[1] === '') {
            item[sub[0]] = pos < lines.length && lines[pos].indent > indent + 2 ? parseBlock(lines[pos].indent) : null;
          } else {
            item[sub[0]] = parseScalar(sub[1]);
          }
        }
        out.push(item);
      } else {
        out.push(parseScalar(rest));
      }
    }
    return out;
  }

  function parseMap(indent) {
    const out = {};
    while (pos < lines.length && lines[pos].indent === indent) {
      const line = lines[pos];
      if (line.text.startsWith('- ')) break;
      const kv = splitKey(line.text);
      if (!kv) throw new Error(`line ${line.n}: expected "key: value", got ${JSON.stringify(line.text)}`);
      pos++;
      if (kv[1] === '') {
        out[kv[0]] = pos < lines.length && lines[pos].indent > indent ? parseBlock(lines[pos].indent) : null;
      } else {
        out[kv[0]] = parseScalar(kv[1]);
      }
    }
    return out;
  }

  const doc = parseBlock(0) ?? {};
  if (pos !== lines.length) {
    throw new Error(`line ${lines[pos].n}: unexpected indentation -- parser stopped early`);
  }
  return doc;
}

// ------------------------------------------------------------------- emitting

export function emitYaml(v, indent = 0) {
  const pad = ' '.repeat(indent);
  const scalar = (x) => {
    if (x === null || x === undefined) return 'null';
    if (typeof x === 'boolean' || typeof x === 'number') return String(x);
    let s = String(x);
    // Values scraped from prose often arrive already wrapped in quotes; emitting
    // them as-is yields "\"...\"" which round-trips to a string WITH the quotes.
    if (s.length > 1 && ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'")))) {
      s = s.slice(1, -1);
    }
    // Quote anything the parser above would read as another type, or that
    // carries YAML punctuation. Cheaper to over-quote than to round-trip wrong.
    return /^[A-Za-z0-9][A-Za-z0-9 ._/@+-]*$/.test(s) && !/^(true|false|null|~)$/.test(s) && !/^-?\d+$/.test(s)
      ? s : JSON.stringify(s);
  };
  if (Array.isArray(v)) {
    if (v.length === 0) return `${pad}[]\n`.replace(pad, pad); // empty list: rare, explicit
    return v.map((item) => {
      if (item !== null && typeof item === 'object' && !Array.isArray(item)) {
        const body = emitYaml(item, indent + 2);
        return `${pad}- ${body.slice(indent + 2)}`;
      }
      return `${pad}- ${scalar(item)}\n`;
    }).join('');
  }
  if (v !== null && typeof v === 'object') {
    return Object.entries(v).map(([k, val]) => {
      if (val !== null && typeof val === 'object') {
        const body = emitYaml(val, indent + 2);
        return body.trim() === '' ? `${pad}${k}:\n` : `${pad}${k}:\n${body}`;
      }
      return `${pad}${k}: ${scalar(val)}\n`;
    }).join('');
  }
  return `${pad}${scalar(v)}\n`;
}

// -------------------------------------------------------------------- schema

// Returns a list of human-readable problems. Empty means valid. The renderer
// refuses to emit on any problem: a plan that renders from malformed input is
// how a step silently disappears from the DAG.
export function validate(plan) {
  const errs = [];
  const push = (m) => errs.push(m);

  if (!plan || typeof plan !== 'object') return ['plan is not a mapping'];
  if (!plan.meta || typeof plan.meta !== 'object') push('meta: missing');
  else if (!plan.meta.title) push('meta.title: missing');

  const steps = plan.steps;
  if (!Array.isArray(steps) || steps.length === 0) return [...errs, 'steps: missing or empty'];

  const ids = new Set();
  for (const s of steps) {
    const at = s && s.id ? `step ${s.id}` : `step #${steps.indexOf(s) + 1}`;
    if (!s || typeof s !== 'object') { push(`${at}: not a mapping`); continue; }
    if (!s.id) { push(`${at}: missing id`); continue; }
    if (!/^[A-Z]\d+$/.test(s.id)) push(`${at}: id must be <LETTER><NUMBER>, e.g. B1`);
    if (ids.has(s.id)) push(`${at}: duplicate id`);
    ids.add(s.id);
    if (!s.title) push(`${at}: missing title`);
    if (!s.status) push(`${at}: missing status`);
    else if (!STATUSES.includes(s.status)) push(`${at}: status ${JSON.stringify(s.status)} not one of ${STATUSES.join('|')}`);
    const wave = s.wave ?? s.id[0];
    if (!/^[A-Z]$/.test(String(wave))) push(`${at}: wave must be a single capital letter`);
    if (s.merge_unit && !(plan.merge_units && plan.merge_units[s.merge_unit])) {
      push(`${at}: merge_unit ${JSON.stringify(s.merge_unit)} is not declared under merge_units`);
    }
  }

  // Dangling and self edges. A dependency on a step that does not exist draws
  // a phantom node in Mermaid rather than erroring, so catch it here.
  for (const s of steps) {
    for (const d of normalizeDeps(s)) {
      if (d.on === s.id) push(`step ${s.id}: depends on itself`);
      else if (!ids.has(d.on)) push(`step ${s.id}: depends on ${d.on}, which is not a step`);
    }
  }

  const cyc = findCycle(steps);
  if (cyc) push(`dependency cycle: ${cyc.join(' -> ')}`);

  // THE wave invariant, ported from the retired deploy-plan-lint.sh: wave X
  // holds X1..Xn, numbered from 1, no gaps. The labels are how the user approves
  // a wave and how the releaser is told what to run, so "run B" must name a set
  // the plan agrees about. A gap usually means a step was deleted rather than
  // renumbered -- and renumbering after the user has seen the plan is its own
  // hazard, so this catches it while the plan is still being written.
  const byWave = new Map();
  for (const s of steps) {
    const w = String(s.wave ?? s.id[0]);
    if (!byWave.has(w)) byWave.set(w, []);
    byWave.get(w).push(s);
  }
  for (const [w, members] of byWave) {
    const wrong = members.filter((s) => s.id[0] !== w);
    if (wrong.length) {
      push(`wave ${w} contains ${wrong.map((s) => s.id).join(', ')} -- every step in wave ${w} must be labelled ${w}<n>`);
    }
    const nums = members.filter((s) => s.id[0] === w).map((s) => Number(s.id.slice(1))).sort((a, b) => a - b);
    const want = nums.map((_, i) => i + 1);
    if (nums.join(',') !== want.join(',')) {
      push(`wave ${w} is numbered ${nums.map((n) => w + n).join(' ')} -- expected ${want.map((n) => w + n).join(' ')} (from 1, no gaps)`);
    }
  }

  return errs;
}

// depends_on accepts either ["A2"] or [{on: A2, kind: ..., why: ...}]; both
// normalize to the object form so callers never branch on it.
export function normalizeDeps(step) {
  const raw = step.depends_on;
  if (!raw) return [];
  const list = Array.isArray(raw) ? raw : [raw];
  return list.filter((d) => d !== null && d !== undefined && d !== '')
    .map((d) => (typeof d === 'object' ? { on: d.on, kind: d.kind ?? null, why: d.why ?? null }
                                       : { on: String(d), kind: null, why: null }));
}

function findCycle(steps) {
  const adj = new Map(steps.map((s) => [s.id, normalizeDeps(s).map((d) => d.on)]));
  const state = new Map();   // 0 unvisited, 1 on stack, 2 done
  const stack = [];
  let found = null;
  const walk = (id) => {
    if (found) return;
    state.set(id, 1); stack.push(id);
    for (const nxt of adj.get(id) ?? []) {
      if (!adj.has(nxt)) continue;              // dangling: reported separately
      if (state.get(nxt) === 1) { found = [...stack.slice(stack.indexOf(nxt)), nxt]; return; }
      if (!state.get(nxt)) walk(nxt);
      if (found) return;
    }
    stack.pop(); state.set(id, 2);
  };
  for (const s of steps) if (!state.get(s.id)) walk(s.id);
  return found;
}

// ---------------------------------------------------------------- derivations

// Every "is this step actionable" question in the plan reduces to this, so it
// lives in one place: a step is ready when it is not finished and every step it
// depends on IS finished. Steps sharing a merge_unit land together, so a unit is
// only ready when all of its members are.
export function computeReady(plan) {
  const byId = new Map(plan.steps.map((s) => [s.id, s]));
  const doneish = (s) => s && (s.status === 'done');
  const ready = new Set();
  for (const s of plan.steps) {
    if (doneish(s) || s.status === 'failed') continue;
    if (normalizeDeps(s).every((d) => doneish(byId.get(d.on)))) ready.add(s.id);
  }
  // A merge unit is atomic: if any member is blocked, none of them are ready.
  const units = new Map();
  for (const s of plan.steps) {
    if (!s.merge_unit) continue;
    if (!units.has(s.merge_unit)) units.set(s.merge_unit, []);
    units.get(s.merge_unit).push(s);
  }
  for (const [, members] of units) {
    if (!members.every((m) => ready.has(m.id) || doneish(m))) {
      members.forEach((m) => ready.delete(m.id));
    }
  }
  return ready;
}

// watch: null | {pr: [repoKey, number]} | {run: [repoKey, id]} | {url: "..."}
export function watchUrl(watch, repos) {
  if (!watch) return null;
  if (typeof watch === 'string') return watch;
  if (watch.url) return watch.url;
  const resolve = (key) => (repos && repos[key]) || key;
  if (watch.pr) {
    const [repo, num] = Array.isArray(watch.pr) ? watch.pr : [watch.repo, watch.pr];
    return `https://github.com/${resolve(repo)}/pull/${num}`;
  }
  if (watch.run) {
    const [repo, id] = Array.isArray(watch.run) ? watch.run : [watch.repo, watch.run];
    return `https://github.com/${resolve(repo)}/actions/runs/${id}`;
  }
  return null;
}

export function wavesOf(plan) {
  const waves = new Map();
  for (const s of plan.steps) {
    const w = String(s.wave ?? s.id[0]);
    if (!waves.has(w)) waves.set(w, []);
    waves.get(w).push(s);
  }
  return [...waves.entries()].sort(([a], [b]) => a.localeCompare(b));
}
