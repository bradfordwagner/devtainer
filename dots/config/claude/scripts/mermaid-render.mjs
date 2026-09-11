// Render payload for mermaid-validate.sh --render. See that script for why.
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { join, resolve } from 'node:path';

const nm = process.env.MERMAID_VALIDATE_MODULES;
if (!nm) {
  console.error('mermaid-render.mjs is a payload -- run mermaid-validate.sh instead');
  process.exit(2);
}
const require = createRequire(join(nm, 'x.cjs'));
const { chromium } = require('playwright-core');

const OFFLINE = process.env.MERMAID_VALIDATE_OFFLINE === '1';

let browser;
try {
  browser = await chromium.launch({ channel: 'chromium-headless-shell' });
} catch (e) {
  console.error(`mermaid-validate: could not launch chromium -- ${String(e.message).split('\n')[0]}`);
  process.exit(2);
}

let failed = 0, checked = 0;
for (const arg of process.argv.slice(2)) {
  const eq = arg.indexOf('=');
  const label = eq > 0 ? arg.slice(0, eq) : arg;
  const path = eq > 0 ? arg.slice(eq + 1) : arg;

  const page = await browser.newPage();
  const notes = [];
  page.on('pageerror', (e) => notes.push(`js error: ${String(e.message).split('\n')[0]}`));
  page.on('requestfailed', (r) =>
    notes.push(`request failed: ${r.url()} (${r.failure()?.errorText})`));
  page.on('response', (r) => {
    if (r.status() >= 400) notes.push(`HTTP ${r.status()}: ${r.url()}`);
  });
  page.on('console', (m) => {
    if (m.type() === 'error') notes.push(`console: ${m.text().slice(0, 200)}`);
  });
  if (OFFLINE) {
    // Prove the page is self-contained: only file:// and data: survive.
    await page.route('**/*', (r) =>
      /^(file|data):/.test(r.request().url()) ? r.continue() : r.abort());
  }

  // file:// on purpose -- it is how the user opens the plan, and it is stricter
  // than http:// (module imports of sibling files are blocked as cross-origin).
  const url = pathToFileURL(resolve(path)).href;
  let blocks;
  try {
    await page.goto(url, { waitUntil: 'load', timeout: 20000 });
    // Wait for a *settled* render. data-processed is set before rendering and
    // the <svg> element appears before it is populated, so either alone is a
    // race that reports a good diagram as an error card. mermaid finishes by
    // stamping aria-roledescription (its error card gets one too, or an
    // .error-icon), which is the first signal that is actually terminal.
    await page
      .waitForFunction(() => {
        const els = [...document.querySelectorAll('pre.mermaid, .mermaid')];
        return els.length > 0 && els.every((el) => {
          const svg = el.querySelector('svg');
          return svg && (svg.hasAttribute('aria-roledescription') || el.querySelector('.error-icon'));
        });
      }, null, { timeout: 20000 })
      .catch(() => {});
    blocks = await page.evaluate(() =>
      [...document.querySelectorAll('pre.mermaid, .mermaid')].map((el, i) => {
        const svg = el.querySelector('svg');
        return {
          i: i + 1,
          id: el.id || null,
          processed: !!el.getAttribute('data-processed'),
          hasSvg: !!svg,
          // mermaid's own error card renders aria-roledescription="error" (or
          // drops the attribute) plus a .error-icon -- a picture of a failure
          // is still a failure.
          role: svg?.getAttribute('aria-roledescription') ?? null,
          errIcon: !!el.querySelector('.error-icon'),
          errText: [...el.querySelectorAll('.error-text')].map((t) => t.textContent).join(' '),
          empty: !svg || svg.getBoundingClientRect().height < 4,
        };
      }));
  } catch (e) {
    console.error(`FAIL  ${label}\n      ${String(e.message).split('\n')[0]}`);
    failed++; checked++;
    await page.close();
    continue;
  }
  await page.close();

  if (!blocks.length) {
    console.error(`FAIL  ${label}\n      no .mermaid block in the rendered page`);
    failed++; checked++;
    continue;
  }

  const uniq = [...new Set(notes)];
  for (const b of blocks) {
    checked++;
    const where = blocks.length === 1 && !b.id
      ? label
      : `${label} [diagram ${b.i}${b.id ? ` #${b.id}` : ''}]`;
    let why = null;
    if (!b.processed) why = 'mermaid never processed this block -- the library did not load or run';
    else if (!b.hasSvg) why = 'no <svg> was produced';
    else if (b.errIcon || b.role === 'error' || b.role === null)
      why = `mermaid rendered its error card${b.errText ? ` -- ${b.errText}` : ''}`;
    else if (b.empty) why = 'the <svg> has no height -- it will look like an empty box';

    if (why) {
      failed++;
      const extra = uniq.length ? `\n${uniq.map((n) => `      ${n}`).join('\n')}` : '';
      console.error(`FAIL  ${where}\n      ${why}${extra}`);
    } else {
      console.log(`ok    ${where} (rendered${OFFLINE ? ', offline' : ''})`);
    }
  }
}

await browser.close();
console.log(`\n${checked - failed}/${checked} diagram(s) render over file://`);
process.exit(failed ? 1 : 0);
