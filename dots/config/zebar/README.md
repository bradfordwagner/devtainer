# zebar

Zebar is the Windows-side bar that GlazeWM launches (`startup_commands: ['shell-exec zebar']`
in `../glazewm/config.yaml`). Deployed by `tasks/windows-wsl.yml` to
`%USERPROFILE%\.glzr\zebar\` on WSL hosts. Run `task bb` after editing.

## Why a vendored pack

`bw-starter/` is a copy of the `glzr-io.starter` marketplace pack, trimmed to the one widget we
use (`with-glazewm`). Upstream's README says to copy a marketplace pack out of
`%AppData%\zebar\downloads\` into `~/.glzr\zebar\` before editing it, otherwise a pack update
overwrites your changes. Zebar discovers local packs one level deep under `~/.glzr/zebar` and
takes the **directory name** as the pack id — hence `bw-starter`, which `settings.json`
references.

Dropped from the upstream copy: `vanilla.html`, `with-komorebi.html`, the preview image, and
the other two widget entries in `zpack.json`.

## Local changes

- **Weather in fahrenheit.** `with-glazewm.html` renders
  `Math.round(output.weather.fahrenheitTemp)}°F`; upstream uses `celsiusTemp` / `°C`. The
  weather provider exposes both fields, so this is purely a display choice — no provider
  config involved.
- **CPU and memory as used/total, plus percent.** `formatCpu` renders
  `6.7/12 (56%)` and `formatMemory` renders `21.4/31.6 GiB (68%)`; upstream showed a bare
  `usage` percentage for each. The memory provider exposes `usedMemory`/`totalMemory` in bytes,
  which `formatUsedTotal` scales to one shared IEC unit. The cpu provider has no used/total
  pair, so "used" is derived as `usage% x logicalCoreCount`; it falls back to the bare
  percentage if the core count is missing. CPU is ordered ahead of memory.
- **Battery time remaining.** The segment renders `58% (5h 6m)` - `formatBatteryTime`
  appends `timeTillFull` while charging and `timeTillEmpty` otherwise, both of which the
  provider reports in **milliseconds**. Upstream showed the percentage alone. The suffix
  collapses to nothing when the provider has no estimate (null at full charge, and briefly
  after a resume before it has sampled a discharge rate), so the segment degrades to
  upstream's bare percentage rather than showing a placeholder. The charging indicator is
  upstream's and unchanged: a 7px yellow plug (`nf-md-power_plug`), absolutely positioned
  just left of the battery glyph by `.charging-icon` in `styles.css`.
- **No network/wifi readout.** The `network` provider, its `getNetworkIcon` helper, and the
  `.network` style were all removed rather than just hidden, so nothing polls for it.
- **No Windows logo.** The `logo` `<i>` and its `.logo` style were removed, so the bar starts
  with the workspace chips.
- **Inconsolata Condensed.** `--font-family` in `styles.css`, ahead of upstream's
  `ui-monospace, monospace` generics, which remain as the fallback. It's a genuine installed
  Windows family (not a synthesised width), so it resolves without a webfont. Icons are
  unaffected — they come from the nerdfonts webfont via the `nf` class on `<i>`.
- **Catppuccin Mocha.** `styles.css` defines the palette as `--ctp-*` custom properties, then
  maps them to role variables (`--text-color`, `--icon-color`, `--accent-color`, …) that the
  rules consume — retheme by editing the `:root` block, not the rules. Upstream's
  `prefers-color-scheme` light/dark split was dropped, since Mocha is dark-only; the bar looks
  the same whatever the Windows app theme is. Swapping to Latte means replacing the palette
  values. GlazeWM's window borders in `../glazewm/config.yaml` use the same palette (mauve
  focused, surface0 unfocused), so change both together.

## Bar height

`zpack.json` sets the `default` preset to `height: '28px'` (upstream ships 40px). GlazeWM's top
outer gap is derived from it (`28px` bar + `4px` gap = `32px`), so **if you change the height
here, update `outer_gap.top` in `../glazewm/config.yaml` to match.**

Going much below 28px starts crowding the content: `styles.css` sets 14px text/icons and the
`.app` rule adds 4px of vertical padding either side, so ~25px is the floor before you'd also
need to shrink those.

## A segment vanishes from the bar

Symptom: one readout is missing while the rest of the bar keeps updating normally. Every
segment is wrapped in `{output.<provider> && ...}`, and the provider group nulls a provider's
entry in `outputMap` the moment it emits an error, so a single sick provider silently removes
its own segment and touches nothing else. `errors.log` in `~/.glzr/zebar/` records pack and
startup failures but *not* a provider that fails at runtime, so a clean log does not clear the
widget.

For the **battery** provider specifically this is an upstream bug, not a config problem, and
the widget now recovers from it on its own - see below. Restarting zebar also clears it:

```powershell
Stop-Process -Name zebar -Force; & 'C:\Program Files\glzr.io\Zebar\zebar.exe' startup
```

### Why the battery segment wedges

zebar 3.3.0 cached the battery handle to fix a resource leak
([#261](https://github.com/glzr-io/zebar/issues/261) /
[#262](https://github.com/glzr-io/zebar/pull/262)). `Manager::new()` and the `Battery` handle
are now acquired **once**, before the poll loop, and every tick calls `manager.refresh(&mut
battery)` on that cached handle. Before 3.3.0 the handle was re-acquired every tick, so a
failed poll healed itself on the next one.

Now nothing re-acquires it. Once the OS invalidates the handle the refresh errors on every
subsequent tick, forever - the loop keeps running and keeps emitting errors, which is why the
rest of the bar is unaffected and why only a restart of the *process* brings the segment back.
3.3.1 is the latest release and still carries this; it is not fixed by upgrading.

### The self-heal

`with-glazewm.html` polls once a minute and calls `providers.raw.battery.restart()` when
`outputMap.battery` has gone null. `restart()` unlistens and re-listens; the desktop side
evicts the provider on the last unlisten and constructs a fresh one on the next listen, which
runs `Manager::new()` again and acquires a good handle. Worth knowing if you touch it:

- Use `restart()`, not `stop()` - `stop()` clears the provider's listener set, which would
  detach the group's `onOutput`/`onError` and leave the segment dead for good. `restart()`
  leaves listeners attached.
- It is gated on having seen a reading at least once (`hasReported`), so a machine with no
  battery reports "No battery found." once and is then left alone rather than restarted every
  minute.
- Recovery costs up to a minute of missing segment. The provider's own refresh interval is 5s,
  so polling faster would only add restart churn for no real gain.
