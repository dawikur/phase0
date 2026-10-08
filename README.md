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

Fonts are generated from the same bitmap glyphs into
`resources/fonts/mip/generated/` and `resources/fonts/amoled/generated/`.
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
