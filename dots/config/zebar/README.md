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

## Bar height

`zpack.json` sets the `default` preset to `height: '40px'`. GlazeWM's top outer gap is derived
from it (`40px` bar + `4px` gap = `44px`), so **if you change the height here, update
`outer_gap.top` in `../glazewm/config.yaml` to match.**
