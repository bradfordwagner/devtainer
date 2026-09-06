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
- **No network/wifi readout.** The `network` provider, its `getNetworkIcon` helper, and the
  `.network` style were all removed rather than just hidden, so nothing polls for it.
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

Going much below 28px starts crowding the content: `styles.css` sets 12px text/icons and the
`.app` rule adds 4px of vertical padding either side, so ~20px is the floor before you'd also
need to shrink those.
