# phase0

Source repository for a Garmin Connect IQ watch face. For the product overview,
see the [phase0 website](https://dawikur.dev/phase0).

## Getting started

You need Python 3, Node.js 22, and the Garmin Connect IQ SDK. The Makefile reads
the active SDK from `~/.Garmin/ConnectIQ/current-sdk.cfg` and creates `.venv`
for Python targets. Release builds also need `CONNECTIQ_DEVELOPER_KEY` and the
pinned Node dependencies (`npm ci`).

```sh
make help            # list targets, arguments, devices, and modes
make test            # Python and website tests
make build           # developer PRG for fr955 (the default device)
```

Use `DEVICE=<id>` to build for another device in `manifest.xml.tmpl`. Build
outputs go to `build/`. `make lint` runs the Python checks and may reformat
files, so review the diff afterward. `make smoke_test` and `make smoke` build
and run every supported device in the Connect IQ simulator. Both stop at the
first application error or failed test, clean up the simulator processes, and
exit with an error.
`make simulate_test` (`make st`) finishes after the test summary and stops its
simulator. It requires an explicit passing summary with no failures or errors;
this also handles SDK 9.2.0 returning exit code 1 because its summary parser
expects a space that the simulator no longer prints.
`make all_tests` runs `lint`, `test`, `smoke_test`, and `smoke` in that order,
stopping at the first failure, including when invoked with `-j`.

## Repository layout

| Path | Purpose |
| --- | --- |
| `source/phase0/`, `source/app.mc` | App lifecycle, view, and layout |
| `source/widgets/` | Reusable watch-face components |
| `source/data/` | Data metrics and formatting |
| `source/utils/` | Rendering, caching, and data providers |
| `data/` | Inputs for generated resources, settings, and devices |
| `resources/` | Source resources and generated resource definitions |
| `scripts/`, `tests/` | Generators, build helpers, and Python tests |
| `site/` | Website source and JavaScript tests |

Edit generator inputs rather than generated files. In particular,
`source/generated/`, `resources/base/generated/`, and generated files in
`build/site/` are build outputs. `make site` copies the website source to
`build/site/` and adds generated data; `make site_update` also refreshes the
shared site UI before rebuilding.

## Display font profiles

Shared fonts are generated from the same bitmap glyphs into
`resources/fonts/mip/generated/` and `resources/fonts/amoled/generated/`.
Icon fonts are generated separately in
`resources/memory/{low,medium,high}/generated/fonts/{mip,amoled}/`.
Generated `build/resources.jungle` selects one font set using the device
catalog's screen type and selects its memory profile independently. Other display types use the MIP set.
Resource IDs and user settings are identical across profiles. Supported AMOLED
devices have fully round screens and meet the minimum Connect IQ API 3.4.0.

Source styles are named `STYLE_1` through `STYLE_4`, with `_BOLD` and `_THIN`
suffixes for existing weight variants. The number is the grid step in pixels;
each style also specifies its dot weight. The generator maps these physical
styles to the roles `regular`, `regular_thin`, `small` and `tiny`, keeping
resource names independent of the chosen display profile.

AMOLED uses a grid step one pixel larger: regular text and both clock digit
shapes use 4 instead of 3, small text and icons use 3 instead of 2, and tiny
labels use 2 instead of 1. Dot weights also increase by one; thin variants
retain one-pixel dots. This means increases of 33%, 50% and 100%, respectively,
rather than uniform scaling. Larger atlases consume more memory on AMOLED,
but only the selected set is packaged and rendering needs no runtime scaling.
Layout continues to measure fonts and use its existing fitting candidates.
Spacing follows the selected grid; the shadow offset stays at one pixel.

`make store` and `make screenshots` also generate `build/store/icon_128_amoled.png`.
This separate 128 × 128 icon uses the AMOLED regular digit styles, preserving
their larger grid and heavier dots. Generate it without the simulator with
`make build/store/icon_128_amoled.png`.
Gauge guide dots are centered within the full bar width; even widths use the
right of the two center pixels.

After changing font profiles, validate a dense layout and AoD on MIP64 and
AMOLED 360/466 px, including long values, side icons, labels and both clock
sizes. Actual layout fit and device memory limits require Connect IQ checks
in an environment where the SDK and simulator work.

## Display modes

On supported AMOLED devices, `App.onDisplayModeChanged()` forwards the
notification to the view, which reads the current system display mode:

| Display mode | Face outside night mode | Face during night mode |
| --- | --- | --- |
| HIGH | Normal | Minimal |
| LOW (always-on display) | Minimal | Minimal |
| OFF | No updates or drawing | No updates or drawing |

The view retains the system display mode and checks it together with cached
night mode to select minimal rendering. The same field holds a hidden state
while the view is not shown; system-mode notifications are ignored until show
reads the current mode again. Night mode is refreshed once per minute and when
the system mode is read.

Minimal uses the existing clock, status and battery presentation. On AMOLED
its background is always black, including night mode with the screen in HIGH;
normal retains the configured background. MIP retains its configured background
in both modes and continues to select minimal through night mode.

AMOLED minimal shifts the clock, status and batteries once per minute. Font
generation computes up to four positions within ±2 px from the actual AMOLED
atlases, including the shadows retained by battery rendering. The generated
`source/generated/burn_in.mc` supplies the offsets; changing fonts recomputes
them, and generation fails if no cycle fits that displacement limit. Rendering
only selects a precomputed position and temporarily offsets existing widgets,
then restores their layout coordinates. It creates no per-update objects.
The `display_mip` / `display_amoled` annotations select separate minimal-update
implementations at compile time. MIP directly renders its widgets; offset
tables and the shifting helper are included only in the AMOLED profile.
The generated `Display.IS_AMOLED` identifies the display profile; `Fonts`
contains font resources and spacing constants.

The generator checks static glyphs, both clock sizes with all possible digits,
battery percentages, remaining-time examples up to 999 with `d`/`h`/`m` suffixes,
and battery bars up to 32 segments. Each tested mask has a black phase in every
cycle, allowing at most three consecutive lit minutes with regular minute
updates. This does not certify arbitrary battery-value transitions, overlapping
widgets or device luminance. Validate screen margins, heat maps and the 10%
luminance limit on a supported AMOLED watch or working simulator after changing
fonts or minimal rendering. MIP and normal rendering retain their positions.

Display mode is read when its callback fires and when the face is shown, rather
than on every update. Returning from OFF refreshes the full face, even within
the same minute; duplicate mode notifications do not request another redraw.
Sleep/wake callbacks independently control update cadence and the partial-update
power budget. Access to the display API is guarded for devices without API 5.0.

Display-mode callbacks, state and mode-reading code are compiled only for
AMOLED. MIP compiles a visibility flag and selects minimal rendering from
night mode, avoiding code that can exceed the 96 KiB limit on Descent Mk2S.
The current manifest supports AMOLED and MIP64 devices; adding an LCD device
requires selecting its display-mode lifecycle independently of its font profile.

Three independent compile-time choices keep unused paths out of each device's
application. The `memory_low` profile renders directly, without a bitmap field
or buffered-rendering code; medium and high retain the buffer and fall back to
direct rendering when memory is insufficient. Only MIP includes partial updates
and their power-budget state. AMOLED keeps normal second rendering while awake
and retains display-mode handling for LOW/OFF.

Icon fonts are selected at compile time by memory profile. Low-memory devices
include only the 34 general icons (status, dawn/dusk, moon phases and the
battery-bar widget). Their MIP icon atlas is 462 × 18. Medium/high devices
also include all 57 conditions icons: rain, wind, solar/UV, temperature,
humidity, battery levels and move bar. The essential/extra split is removed.
This reduces the font allocation and excludes conditions icon-selection code
on low-memory devices. All metric values, labels and gauges remain available;
Style = Icon reserves no space for a conditions icon on low. Digit and text
fonts continue to use the shared display profiles.

Touch handlers are included only with `input_touch`. The device catalog records
`supports_touch` from the SDK's `simulator.json` (`display.isTouch`); generating
Jungle does not require the SDK and rejects supported devices whose capability
is unknown. MIP devices can have touch screens, so input is independent of the
font profile. Weather forecast selection remains based on available memory.

Manual validation requires a working SDK/simulator environment or a watch:
exercise HIGH→LOW→HIGH and HIGH/LOW→OFF→HIGH/LOW, start/show in each mode,
and repeat transitions within a minute. With a bright configured background,
check that AMOLED minimal is black and normal restores that background. Check
night mode boundaries, hidden widget touch areas, and AoD burn-in limits on an
AMOLED device; on MIP64, verify the existing night mode and partial seconds
updates. Also check that sleep/wake callback order does not change the selected
presentation.
For Descent Mk2S, verify startup, minute changes, night mode and partial-update
budget fallback. On FR955, also verify touch-and-hold widget navigation and both
buffered and direct rendering. On Venu2, verify awake seconds, sleep/wake and
HIGH/LOW/OFF transitions. Compare code/data and peak memory in the same build
mode before and after changes; the whole PRG file size is not a RAM measurement.

## Build channels

`make build` creates a device-specific developer PRG. To test a Store identity
on a watch, select its channel, for example `make build CHANNEL=alpha`. To
create uploadable, release-mode IQ packages, run `make alpha`, `make beta`, or
`make iq` (`build/phase0.iq` for the public release). Run `npm ci` before these
release builds.

The manifest generator assigns a stable ID to each channel using the shared
`manifest.xml.tmpl`. Developer is for PRG testing; alpha is a private Garmin
Beta App; beta is a separate public test listing; release is the public watch
face. Keep each ID with its existing Store listing so installations and
settings stay separate.

## Project documents

- [AGENTS.md](AGENTS.md) — architecture, performance, and repository rules.
- [TODO.md](TODO.md) — product and technical backlog.
- [CHANGELOG.md](CHANGELOG.md) — release history.
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) — build, upload, and watch checks.

## Temperatures

Temperature reads the watch's temperature sensor once per minute, using the
sensor provider's cache when no fresh sample is available. Wrist heat can affect
this reading. Feels-like temperature and daily high/low values use weather data
and share the weather provider's refresh, retry and cache policy.
Temperature, feels-like temperature, and daily high/low values follow the watch's
temperature units (Celsius or Fahrenheit). Their icons are selected in Celsius,
with thresholds at −25, −15, −5, 5, 15 and 25 °C; a value exactly on a threshold
uses the warmer icon. Missing values clear both the value and icon.

On FR955 (MIP64) and Venu2 (AMOLED), manually check all four metrics in both
unit systems, including negative values, icon thresholds and missing sensor/weather data.
For example, 0 °C should display as 32 °F with the same icon. Check that newly
available weather updates the face and unchanged values do not cause redraws.

## Metric width

Metric Width offers Auto (the data's default), None and 1–10. None (`Properties.NONE`)
hides the numeric value and its spacing while retaining the selected icon or gauge and
the usual label. A metric without an icon/gauge shows only its label. Hidden
values are not formatted, and icon-only widgets redraw only when their icon
changes. Gauge widgets still update from the underlying value.

Stored width 0 previously meant Auto; it now selects None and hides the value.
Use Auto (−1) to retain automatic width. On FR955 and Venu2, check Width None
with icon, gauge and plain metrics, labels enabled/disabled, missing data and
both narrow side slots and middle rows.

All Auto settings use −1, including Clock Size and Metric Width. Previously
saved Clock Size = 3 still behaves as Auto; the IDs of other options remain
unchanged.

## Humidity icons

Relative humidity supports both icon and gauge widgets. The five droplet icons
represent 0–24%, 25–29%, 30–59%, 60–69% and 70–100%, respectively. Missing
weather data clears the value and icon. Width None can display only the icon
with the usual label. On FR955 and Venu2, check each threshold and missing data.

## Move Bar icons

Move Bar supports icon and gauge widgets. Each level from 0 through 5 selects
its matching icon; level 0 uses an empty icon. Missing data clears the icon.
Width None hides the number while retaining the icon and usual label.
On FR955 and Venu2, check all six levels, missing data and icon-only rendering.

## Battery metric icons

Battery Percentage and Body Battery share five battery icons: 0–9 → 0,
10–36 → 1, 37–63 → 2, 64–90 → 3 and 91–100 → 4. The three middle ranges
contain 27 integer values each. Missing data clears the icon. Both metrics
support icon and gauge widgets, including Width None to hide the number.
On FR955 and Venu2, check each boundary, missing Body Battery data and
icon-only rendering.

Battery Days Remaining uses the same battery icons and percentage thresholds,
while its numeric value remains the estimated number of days. It reuses the
system-stats snapshot already read for that estimate. If the estimate is
unavailable, the percentage icon still appears, including with Width None.
On FR955 and Venu2, check percentage boundaries and an unavailable day estimate.

## Solar icons

UV Index and Solar Intensity share the five `solar 0` through `solar 4` icons.
UV keeps its existing thresholds at 2, 5, 7 and 9. Solar Intensity selects icons
at 20, 40, 60 and 80 on its 0–100 scale. Missing or negative solar readings
clear the value and icon. Solar Intensity supports both icon and gauge widgets.
On FR955 Solar, check each solar threshold and negative readings; on Venu2,
check that unsupported solar data remains empty. Check UV icons on both devices.

Metric setting IDs are stable hashes of `DATA_` plus the metric name, computed
once during resource generation. Adding a metric no longer shifts existing
choices. Filtered metric lists and extra widget options retain their original
IDs. During beta, setting IDs may change without migrating previous choices.

Auto and None use stable hashed option IDs just like other named options.
Runtime checks use `Properties.AUTO` and `Properties.NONE`; numeric metric
widths remain 1–10. Settings are read directly using current IDs.
The Global color choice uses the shared hashed `Properties.GLOBAL` ID;
widgets resolve it to the corresponding global color during construction.
