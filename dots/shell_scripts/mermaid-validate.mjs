// Payload for mermaid-validate.sh -- see that script for why this exists.
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const nm = process.env.MERMAID_VALIDATE_MODULES;
if (!nm) {
  console.error('mermaid-validate.mjs is a payload -- run mermaid-validate.sh instead');
  process.exit(2);
}
const require = createRequire(join(nm, 'x.cjs'));

// jsdom before mermaid: mermaid's DOMPurify grabs `window` at import time.
const { JSDOM } = require('jsdom');
const dom = new JSDOM('<!doctype html><html><body></body></html>');
global.window = dom.window;
global.document = dom.window.document;

const mermaid = (await import(join(nm, 'mermaid', 'dist', 'mermaid.core.mjs'))).default;
mermaid.initialize({ startOnLoad: false });

const numbered = (src) =>
  src.split('\n').map((l, i) => `      ${String(i + 1).padStart(3)} | ${l}`).join('\n');

// How the browser sees a diagram: mermaid.run() reads element.innerHTML and then
// runs it through entityDecode + dedent before handing it to the grammar. Both
// steps are reproduced here, because innerHTML is a *serialisation* -- a literal
// `>` in the source comes back as `&gt;`, which the grammar rejects as a lexical
// error. Scraping the <pre> with a regex, or skipping the decode, would report
// failures on diagrams that render perfectly.
const decoder = dom.window.document.createElement('div');
const entityDecode = (html) => {
  // mermaid's own: percent-escape first so tags survive, restore only & # ;
  // so entities decode, then unescape what is left.
  decoder.innerHTML = escape(html).replace(/%26/g, '&').replace(/%23/g, '#').replace(/%3B/g, ';');
  return unescape(decoder.textContent);
};

let dedent = (s) => s;
try {
  dedent = require(join(nm, 'ts-dedent')).dedent;
} catch {
  // hoisting is not guaranteed; the grammar tolerates uniform indentation.
}

const normalise = (txt) =>
  dedent(entityDecode(txt)).trim().replace(/<br\s*\/?>/gi, '<br/>');

function extract(path, label) {
  const raw = readFileSync(path, 'utf8');
  if (!/\.html?$/i.test(path)) return [{ where: label, src: raw.trim() }];
  const d = new JSDOM(raw);
  // A valid diagram in a page that never loads mermaid still shows as an empty
  // box, so it is worth one line of warning even though it parses fine.
  if (!/mermaid[^"']*\.(m?js)/.test(raw) && !/mermaid\.initialize/.test(raw)) {
    console.error(`warn  ${label}: no mermaid script found -- diagrams will not render in a browser`);
  }
  const nodes = [...d.window.document.querySelectorAll('pre.mermaid, .mermaid')];
  return nodes.map((el, i) => ({
    where: nodes.length === 1 && !el.id ? label
         : `${label} [diagram ${i + 1}${el.id ? ` #${el.id}` : ''}]`,
    src: normalise(el.innerHTML),
  }));
}

// A path may be given as `<label>=<path>` so the caller can name stdin something
// friendlier than its temp file.
let failed = 0, checked = 0;
for (const arg of process.argv.slice(2)) {
  const eq = arg.indexOf('=');
  const label = eq > 0 ? arg.slice(0, eq) : arg;
  const path = eq > 0 ? arg.slice(eq + 1) : arg;

  let blocks;
  try {
    blocks = extract(path, label);
  } catch (e) {
    console.error(`FAIL  ${label}\n      ${e.message}`);
    failed++; checked++;
    continue;
  }
  if (!blocks.length) {
    console.error(`FAIL  ${label}\n      no .mermaid block found -- the diagram is missing, not malformed`);
    failed++; checked++;
    continue;
  }
  for (const { where, src } of blocks) {
    checked++;
    if (!src) {
      console.error(`FAIL  ${where}\n      empty diagram`);
      failed++;
      continue;
    }
    try {
      await mermaid.parse(src);
      console.log(`ok    ${where}`);
    } catch (e) {
      failed++;
      const msg = String(e?.message ?? e).split('\n').map((l) => `      ${l}`).join('\n');
      console.error(`FAIL  ${where}\n${msg}\n      --- source as the browser sees it ---\n${numbered(src)}`);
    }
  }
}

console.log(`\n${checked - failed}/${checked} diagram(s) parse`);
process.exit(failed ? 1 : 0);
