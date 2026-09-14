#!/usr/bin/env node
// deploy-plan.yaml -> deploy-plan.html
//
//   deploy-plan-render.mjs [plan.yaml] [-o out.html]
//
// The DAG is the product. Everything else on the page -- legend, wave table,
// step detail -- is subordinate to it, which is why the diagram gets the
// viewport and the detail lives in a panel you open by clicking a node.
//
// This file owns the page chrome permanently so that bw-release-planner does
// not re-derive it on every run. The planner writes the YAML; the shape of the
// output is not its problem. Status classes, checkbox state, ready-set, wave
// grouping and merge-unit boxes are all DERIVED (see deploy-plan-model.mjs) --
// never hand-written, so the HTML cannot drift from the data the way two
// hand-maintained files did.

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { parseYamlSubset, validate, normalizeDeps, computeReady, watchUrl, wavesOf, STATUSES }
  from './deploy-plan-model.mjs';

const argv = process.argv.slice(2);
let src = null, out = null;
for (let i = 0; i < argv.length; i++) {
  if (argv[i] === '-o' || argv[i] === '--out') out = argv[++i];
  else if (argv[i] === '-h' || argv[i] === '--help') {
    console.log('usage: deploy-plan-render.mjs [plan.yaml] [-o out.html]');
    process.exit(0);
  } else src = argv[i];
}
src = resolve(src ?? 'deploy-plan.yaml');
out = resolve(out ?? src.replace(/\.ya?ml$/, '.html'));

if (!existsSync(src)) { console.error(`deploy-plan-render: no such file: ${src}`); process.exit(2); }

let plan;
try {
  plan = parseYamlSubset(readFileSync(src, 'utf8'));
} catch (e) {
  console.error(`deploy-plan-render: ${src}: ${e.message}`);
  process.exit(2);
}

const errs = validate(plan);
if (errs.length) {
  // Refuse rather than render. A plan that renders from malformed input is how
  // a step silently disappears from the diagram.
  console.error(`deploy-plan-render: ${src} is not a valid plan:`);
  errs.forEach((e) => console.error(`  - ${e}`));
  process.exit(1);
}

const esc = (s) => String(s ?? '')
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;');

// Mermaid node labels are not HTML: quotes end the label and break the parse.
const mm = (s) => String(s ?? '').replace(/"/g, "'").replace(/[[\]{}()]/g, ' ').replace(/\s+/g, ' ').trim();

const repos = (plan.meta && plan.meta.repos) || {};
const ready = computeReady(plan);
const byId = new Map(plan.steps.map((s) => [s.id, s]));
const waves = wavesOf(plan);

// Prose bodies stay in their own markdown files, unmigrated and unrewritten.
// Rendered as <pre> rather than parsed: the renderer is not a markdown engine,
// and a half-implemented one would mangle the tables and code blocks these
// bodies contain.
const planDir = dirname(src);
function bodyOf(step) {
  if (!step.body) return null;
  const p = join(planDir, step.body);
  if (!existsSync(p)) return `(body file not found: ${step.body})`;
  return readFileSync(p, 'utf8');
}

// -------------------------------------------------------------- mermaid source

const statusClass = (s) => (ready.has(s.id) && s.status === 'pending' ? 'ready' : s.status);

// A merge unit that spans waves must be ONE box, not one per wave. Waves are
// promotion ordering; a merge unit is a single PR and a single merge event.
// Drawing B1-B4 and C1-C3 as "Wave B" + "Wave C" when they are one PR shows the
// reader the opposite of the decision that was made -- which is precisely the
// failure that made the hand-written diagram unable to express this.
const unitWaves = new Map();
for (const s of plan.steps) {
  if (!s.merge_unit) continue;
  if (!unitWaves.has(s.merge_unit)) unitWaves.set(s.merge_unit, new Set());
  unitWaves.get(s.merge_unit).add(String(s.wave ?? s.id[0]));
}
const spanning = new Set([...unitWaves].filter(([, w]) => w.size > 1).map(([u]) => u));

const slug = (x) => String(x).replace(/[^A-Za-z0-9]/g, '_');
let mermaid = 'graph TD\n';

// Spanning units first, as top-level boxes of their own.
for (const unit of spanning) {
  const members = plan.steps.filter((s) => s.merge_unit === unit);
  const waveList = [...unitWaves.get(unit)].sort().join('+');
  mermaid += `  subgraph MU_${slug(unit)}["◆ ${mm(unit)} — ONE PR, one merge (waves ${waveList})"]\n`;
  for (const s of members) mermaid += `    ${s.id}["${mm(s.id)} · ${mm(s.title)}"]\n`;
  mermaid += '  end\n';
}

for (const [wave, steps] of waves) {
  const rest = steps.filter((s) => !spanning.has(s.merge_unit));
  if (!rest.length) continue;   // whole wave absorbed into a spanning unit
  mermaid += `  subgraph W${wave}["Wave ${wave}"]\n`;
  // A merge unit inside a single wave stays nested in it.
  const units = new Map();
  for (const s of rest) {
    const k = s.merge_unit ?? null;
    if (!units.has(k)) units.set(k, []);
    units.get(k).push(s);
  }
  for (const [unit, members] of units) {
    const nested = unit && members.length > 1;
    if (nested) mermaid += `    subgraph U_${wave}_${slug(unit)}["${mm(unit)} (one PR)"]\n`;
    for (const s of members) {
      mermaid += `${nested ? '      ' : '    '}${s.id}["${mm(s.id)} · ${mm(s.title)}"]\n`;
    }
    if (nested) mermaid += '    end\n';
  }
  mermaid += '  end\n';
}
for (const s of plan.steps) {
  for (const d of normalizeDeps(s)) {
    mermaid += d.kind ? `  ${d.on} -->|${mm(d.kind)}| ${s.id}\n` : `  ${d.on} --> ${s.id}\n`;
  }
}
mermaid += '\n';
for (const st of [...STATUSES, 'ready']) {
  const ids = plan.steps.filter((s) => statusClass(s) === st).map((s) => s.id);
  if (ids.length) mermaid += `  class ${ids.join(',')} ${st}\n`;
}
mermaid += `  classDef done    fill:#2a3b2a,stroke:#a6e3a1,stroke-width:2px,color:#a6e3a1
  classDef active  fill:#3d3a24,stroke:#f9e2af,stroke-width:3px,color:#f9e2af
  classDef ready   fill:#1e2b3a,stroke:#89b4fa,stroke-width:2px,color:#89b4fa
  classDef pending fill:#1e1e2e,stroke:#45475a,color:#6c7086
  classDef blocked fill:#1e1e2e,stroke:#45475a,color:#6c7086
  classDef failed  fill:#4a2733,stroke:#f38ba8,stroke-width:3px,color:#f38ba8
`;
for (const s of plan.steps) mermaid += `  click ${s.id} call stepClick("${s.id}")\n`;

// ------------------------------------------------------------------- the page

const counts = Object.fromEntries([...STATUSES, 'ready'].map((st) =>
  [st, plan.steps.filter((s) => statusClass(s) === st).length]));

const stepData = Object.fromEntries(plan.steps.map((s) => {
  const unit = s.merge_unit ? (plan.merge_units ?? {})[s.merge_unit] : null;
  return [s.id, {
    id: s.id,
    title: s.title,
    status: statusClass(s),
    wave: String(s.wave ?? s.id[0]),
    sha: s.sha ?? null,
    command: s.command ?? null,
    gate: s.gate ?? null,
    reversible: s.reversible ?? null,
    target: s.target ?? null,
    merge_unit: s.merge_unit ?? null,
    merge_unit_detail: unit ? `${unit.repo ?? ''} ${unit.branch ?? ''}`.trim() : null,
    deps: normalizeDeps(s).map((d) => ({ ...d, title: byId.get(d.on)?.title ?? null })),
    blocks: plan.steps.filter((o) => normalizeDeps(o).some((d) => d.on === s.id)).map((o) => o.id),
    watch: watchUrl(s.watch, repos),
    body: bodyOf(s),
  }];
}));

// meta.legend (alias -> real cluster/app identifier) takes precedence; the repo
// map is a fallback so a plan without an explicit legend still resolves names.
const legendSrc = (plan.meta && plan.meta.legend) || repos;
const legendRows = Object.entries(legendSrc)
  .map(([k, v]) => `<tr><td><code>${esc(k)}</code></td><td>${esc(v)}</td></tr>`).join('');

const html = `<meta charset="utf-8">
<title>${esc(plan.meta.title)}</title>
<style>
  :root {
    --bg:#11111b; --fg:#cdd6f4; --dim:#6c7086; --line:#313244; --panel:#181825;
    --green:#a6e3a1; --yellow:#f9e2af; --blue:#89b4fa; --red:#f38ba8;
  }
  * { box-sizing: border-box; }
  body {
    margin:0; background:var(--bg); color:var(--fg);
    font:14px/1.5 ui-sans-serif,-apple-system,"Segoe UI",system-ui,sans-serif;
    height:100vh; display:flex; flex-direction:column; overflow:hidden;
  }
  header { padding:10px 16px; border-bottom:1px solid var(--line); display:flex; gap:16px; align-items:baseline; flex-wrap:wrap; }
  h1 { font-size:15px; margin:0; font-weight:600; }
  .counts { display:flex; gap:12px; font-size:12px; margin-left:auto; }
  .counts b { font-weight:600; }
  .done{color:var(--green)} .active{color:var(--yellow)} .ready{color:var(--blue)}
  .failed{color:var(--red)} .pending,.blocked{color:var(--dim)}
  main { flex:1; display:flex; min-height:0; }
  #dag { flex:1; position:relative; overflow:hidden; cursor:grab; }
  #dag.grabbing { cursor:grabbing; }
  #pan { transform-origin:0 0; position:absolute; top:0; left:0; padding:24px; }
  #pan svg { max-width:none !important; height:auto !important; }
  .ctl { position:absolute; top:10px; right:10px; z-index:5; display:flex; gap:4px; }
  .ctl button {
    width:30px; height:30px; border:1px solid var(--line); background:var(--panel);
    color:var(--fg); border-radius:5px; cursor:pointer; font-size:14px; line-height:1;
  }
  .ctl button:hover { border-color:var(--blue); }
  .hint { position:absolute; bottom:10px; left:14px; font-size:11px; color:var(--dim); }
  aside {
    width:min(46ch,42vw); border-left:1px solid var(--line); background:var(--panel);
    overflow-y:auto; padding:16px; display:none;
  }
  aside.open { display:block; }
  aside h2 { font-size:14px; margin:0 0 2px; }
  aside .sub { color:var(--dim); font-size:12px; margin-bottom:14px; }
  aside section { margin-bottom:14px; }
  aside h3 { font-size:11px; text-transform:uppercase; letter-spacing:.05em; color:var(--dim); margin:0 0 4px; font-weight:600; }
  pre { background:#0d0d15; border:1px solid var(--line); border-radius:5px; padding:9px; overflow-x:auto; font-size:12px; margin:0; white-space:pre-wrap; }
  code { font-family:ui-monospace,"Cascadia Code",Menlo,monospace; font-size:12px; }
  a { color:var(--blue); }
  table { border-collapse:collapse; font-size:12px; width:100%; }
  td,th { border:1px solid var(--line); padding:3px 7px; text-align:left; }
  .close { float:right; background:none; border:none; color:var(--dim); cursor:pointer; font-size:18px; line-height:1; }
  .pill { display:inline-block; padding:1px 7px; border-radius:9px; font-size:11px; border:1px solid currentColor; }
  .empty { color:var(--dim); font-size:12px; }
</style>

<header>
  <h1>${esc(plan.meta.title)}</h1>
  <div class="counts">
    ${['done', 'active', 'ready', 'pending', 'blocked', 'failed']
      .filter((k) => counts[k]).map((k) => `<span class="${k}"><b>${counts[k]}</b> ${k}</span>`).join('')}
  </div>
</header>

<main>
  <div id="dag">
    <div class="ctl">
      <button id="zin" title="Zoom in">+</button>
      <button id="zout" title="Zoom out">&minus;</button>
      <button id="zfit" title="Fit">&#10021;</button>
    </div>
    <div id="pan"><pre class="mermaid">${esc(mermaid)}</pre></div>
    <div class="hint">scroll to zoom · drag to pan · click a step for detail</div>
  </div>
  <aside id="panel"></aside>
</main>

<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';

const STEPS = ${JSON.stringify(stepData)};
const LEGEND = ${JSON.stringify(legendRows)};

// stepClick must exist before mermaid binds its click handlers.
window.stepClick = (id) => {
  const s = STEPS[id];
  if (!s) return;
  const esc = (t) => String(t ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  const sec = (h, b) => b ? \`<section><h3>\${h}</h3>\${b}</section>\` : '';
  const p = document.getElementById('panel');
  p.innerHTML = \`
    <button class="close" onclick="document.getElementById('panel').classList.remove('open')">&times;</button>
    <h2>\${esc(s.id)} · \${esc(s.title)}</h2>
    <div class="sub">
      <span class="pill \${s.status}">\${esc(s.status)}</span>
      wave \${esc(s.wave)}\${s.merge_unit ? ' · merge unit <code>' + esc(s.merge_unit) + '</code>' : ''}
    </div>
    \${sec('Watch', s.watch ? \`<a href="\${esc(s.watch)}" target="_blank" rel="noopener">\${esc(s.watch)}</a>\`
                            : '<div class="empty">no URL yet &mdash; the object does not exist until this step runs</div>')}
    \${sec('Merged as', s.sha ? \`<code>\${esc(s.sha)}</code>\` : null)}
    \${sec('Command', s.command ? \`<pre>\${esc(s.command)}</pre>\` : null)}
    \${sec('Gate', s.gate ? \`<pre>\${esc(s.gate)}</pre>\` : null)}
    \${sec('Depends on', s.deps.length
      ? '<table>' + s.deps.map(d => \`<tr><td><code>\${esc(d.on)}</code></td><td>\${esc(d.kind ?? '')}\${d.why ? ' &mdash; ' + esc(d.why) : ''}</td></tr>\`).join('') + '</table>'
      : '<div class="empty">nothing</div>')}
    \${sec('Blocks', s.blocks.length ? s.blocks.map(b => \`<code>\${esc(b)}</code>\`).join(' ') : '<div class="empty">nothing</div>')}
    \${sec('Reversible', s.reversible ? esc(s.reversible) : null)}
    \${sec('Target', s.target ? esc(s.target) : null)}
    \${sec('Detail', s.body ? \`<pre>\${esc(s.body)}</pre>\` : null)}
    \${sec('Legend', LEGEND ? '<table>' + LEGEND + '</table>' : null)}\`;
  p.classList.add('open');
};

mermaid.initialize({ startOnLoad:false, theme:'dark', securityLevel:'loose',
                     flowchart:{ useMaxWidth:false, htmlLabels:true } });
await mermaid.run({ querySelector:'.mermaid' });

// Pan/zoom over the rendered SVG. Plain transforms -- no second CDN dep.
const dag = document.getElementById('dag'), pan = document.getElementById('pan');
let scale = 1, tx = 0, ty = 0;
const apply = () => { pan.style.transform = \`translate(\${tx}px,\${ty}px) scale(\${scale})\`; };
const fit = () => {
  const svg = pan.querySelector('svg'); if (!svg) return;
  const b = svg.getBoundingClientRect(), d = dag.getBoundingClientRect();
  scale = Math.min(d.width / (b.width / scale || 1), d.height / (b.height / scale || 1), 1.6) * 0.92;
  tx = 0; ty = 0; apply();
};
dag.addEventListener('wheel', (e) => {
  e.preventDefault();
  const r = dag.getBoundingClientRect(), mx = e.clientX - r.left, my = e.clientY - r.top;
  const f = e.deltaY < 0 ? 1.12 : 1 / 1.12, ns = Math.min(Math.max(scale * f, 0.15), 6);
  // Keep the point under the cursor fixed while zooming.
  tx = mx - (mx - tx) * (ns / scale); ty = my - (my - ty) * (ns / scale);
  scale = ns; apply();
}, { passive:false });
let drag = null;
dag.addEventListener('mousedown', (e) => { drag = { x:e.clientX - tx, y:e.clientY - ty }; dag.classList.add('grabbing'); });
addEventListener('mousemove', (e) => { if (drag) { tx = e.clientX - drag.x; ty = e.clientY - drag.y; apply(); } });
addEventListener('mouseup', () => { drag = null; dag.classList.remove('grabbing'); });
document.getElementById('zin').onclick  = () => { scale = Math.min(scale * 1.25, 6); apply(); };
document.getElementById('zout').onclick = () => { scale = Math.max(scale / 1.25, 0.15); apply(); };
document.getElementById('zfit').onclick = fit;
addEventListener('keydown', (e) => { if (e.key === 'Escape') document.getElementById('panel').classList.remove('open'); });
fit();
</script>
`;

writeFileSync(out, html);

// ------------------------------------------------------- the releaser's copy
//
// bw-release-releaser reads the .md, not the .html, and its prompt pins the
// shape: a checkbox index, then ## Legend, then ## Context with one ### section
// per label carrying Command / Gate / Depends on / Reversible? / Target and a
// Watch line. Generating it from the same YAML is what makes the two files
// unable to disagree -- the failure this whole change exists to end.
//
// Consequence worth stating plainly: this file is now GENERATED. Hand-editing
// it is silently undone by the next render. The header says so.

const mdOut = out.replace(/\.html$/, '.md');
let mdDoc = `# ${plan.meta.title}\n\n`
  + `<!-- GENERATED by deploy-plan-render.mjs from deploy-plan.yaml. Do not hand-edit:\n`
  + `     the next render overwrites it. Change the YAML (or steps/<ID>.md) instead. -->\n\n`;

for (const [wave, steps] of waves) {
  mdDoc += `<!-- wave ${wave} -->\n`;
  for (const s of steps) {
    const box = s.status === 'done' ? 'x' : ' ';
    const unit = s.merge_unit && steps.filter((o) => o.merge_unit === s.merge_unit).length > 1
      ? ` · one PR with ${plan.steps.filter((o) => o.merge_unit === s.merge_unit && o.id !== s.id).map((o) => o.id).join('/')}`
      : '';
    const st = s.status === 'done' ? '' : ` — ${statusClass(s)}${unit}`;
    mdDoc += `- [${box}] ${s.id} — ${s.title}${st}${s.sha ? ` (\`${s.sha}\`)` : ''}\n`;
  }
  mdDoc += '\n';
}

if (Object.keys(legendSrc).length) {
  mdDoc += `## Legend\n\n| Alias | Real identifier |\n|---|---|\n`;
  for (const [k, v] of Object.entries(legendSrc)) mdDoc += `| \`${k}\` | ${v} |\n`;
  mdDoc += '\n';
}

mdDoc += `## Context\n\n`;
for (const s of plan.steps) {
  const d = stepData[s.id];
  mdDoc += `### ${s.id} — ${s.title}\n`;

  // A migrated body already carries its own **Command:** / **Gate:** /
  // **Depends on:** lines, extracted from this very text. Emitting the YAML
  // copies too would duplicate every field -- measured at 34 Watch lines for 17
  // steps. So: emit a field only when the body does not already state it, and
  // let the body win, since it is what a human wrote and reviewed.
  const bodyText = d.body ? d.body.replace(/^###\s+\S+\s*—.*\n/, '').trim() : '';
  if (bodyText) mdDoc += `${bodyText}\n\n`;
  const states = (label) => new RegExp(`\\*\\*${label}`).test(bodyText);

  if (d.command && !states('Command'))       mdDoc += `**Command:**\n\`\`\`\n${d.command}\n\`\`\`\n`;
  if (d.gate && !states('Gate'))             mdDoc += `**Gate:** ${d.gate}\n`;
  if (!states('Depends on')) {
    mdDoc += `**Depends on:** ${d.deps.length
      ? d.deps.map((x) => `${x.on}${x.kind ? ` (${x.kind})` : ''}`).join(', ') : 'none'}\n`;
  }
  if (d.reversible && !states('Reversible')) mdDoc += `**Reversible?** ${d.reversible}\n`;
  if (d.target && !states('Target'))         mdDoc += `**Target:** ${d.target}\n`;
  // The releaser's prompt treats a missing Watch line as "derive it yourself
  // and say you derived it". An explicit `none` is the stronger statement: the
  // object does not exist yet, so there is nothing to derive and nothing to guess.
  if (!/- \*\*Watch\*\*/.test(bodyText)) mdDoc += `- **Watch** — ${d.watch ?? 'none'}\n`;
  mdDoc += '\n';
}

writeFileSync(mdOut, mdDoc);

const summary = ['done', 'active', 'ready', 'pending', 'blocked', 'failed']
  .filter((k) => counts[k]).map((k) => `${counts[k]} ${k}`).join(', ');
console.log(`deploy-plan-render: ${out}`);
console.log(`deploy-plan-render: ${mdOut}`);
console.log(`  ${plan.steps.length} steps: ${summary}`);
