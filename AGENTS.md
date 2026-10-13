# phase0

`phase0` is a Garmin Connect IQ watch face focused on minimalism, performance
and battery efficiency.

This document describes how AI agents should work within this repository.

---

## Project goals

Priority order:

1. Correctness
1. Rendering performance
1. Battery life
1. Maintainability
1. Simplicity
1. Small binary size

Never sacrifice performance for abstraction.

---

## Technology

- Garmin Connect IQ
- Monkey C
- Makefile build
- GitHub
- Cloudflare Pages documentation

Documentation is generated separately and copied into the website repository.
Keep `site/` as the website source module, including its tests and generator
inputs; `make site` copies it to `build/site/` and adds generated data there.
`make site` is incremental; use `make site-update` when the shared `site-ui`
repository should be fetched before rebuilding the site.

---

## Repository map

- `source/phase0/` — application lifecycle, view and layout
- `source/widgets/` — reusable watch-face UI components
- `source/data/` — individual data metrics and their formatting
- `source/utils/` — rendering, caching, runtime and data providers
- `data/` — inputs for generated resources and settings
- `resources/` — source resources and generated resource definitions
- `README.md` — project entry point and product description
- `TODO.md` — compact product and technical backlog
- `CHANGELOG.md` — release history

Do not edit generated files by hand. In particular, treat
`source/generated/`, `resources/base/generated/`, `build/site/settings-data.js` and
`build/site/devices-data.js` as
build outputs; change their source data or generator instead.

Memory-specific resources belong in `resources/memory/low/`,
`resources/memory/medium/` or `resources/memory/high/`. Their device mapping and
`memory_low`, `memory_medium` and `memory_high` source exclusions are generated
from the release manifest rendered from `manifest.xml.tmpl` and
`data/devices`; inverse annotations
`memory_not_low`, `memory_not_medium` and `memory_not_high` are also generated
so a declaration can be included in every profile except one. Monkey C
annotation names use underscores because hyphens are not valid in annotations.

Use `memory_not_low` for the bitmap field and buffered-rendering implementation;
`memory_low` must compile direct rendering without bitmap state. Profile-specific
prepare/reset/clear helpers are empty on low-memory devices. Preserve the
allocation guard and direct-rendering fallback on medium/high devices.

Input annotations `input_touch` and `input_not_touch` are independent of memory
and display profiles. Record `Device.supports_touch` from installed SDK
`simulator.json` / `display.isTouch` for every manifest-supported device. Unknown
is `None`, not false; Jungle generation rejects an unknown supported capability
and must not depend on an installed SDK. Include press callbacks and the view's
touch handler only with `input_touch`; keep widget APIs and API guards shared.

---

## Philosophy

The watch face should feel native.

Avoid solutions that:

- allocate memory every update
- redraw unnecessarily
- introduce hidden complexity
- require excessive abstraction
- use client-side caches or persistent browser storage for website state

Prefer explicit code over clever code.

---

## Rendering rules

Rendering is the most performance-critical part of the application.

Always assume:

- OnUpdate() may execute every second.
- Battery consumption matters.
- Drawing operations are expensive.

Prefer:

- partial redraws
- dirty rectangles
- cached values
- cached layouts

Center gauge guide dots within the full bar width. For even widths, use the
right of the two center pixels.

Avoid:

- full screen redraws
- recreating objects
- repeated calculations
- repeated string formatting

Full-screen redraws are appropriate only when the complete visual state must
change, such as initial rendering, layout or setting changes, theme changes,
or waking from sleep. They are not appropriate for routine clock updates.

Position the top and bottom inner rows as though all three rows on that side
were available. Visible middle and outer rows share the remaining space
dynamically, so hiding either one does not move the inner row.

---

## Memory allocations

Avoid allocations inside rendering.

Never allocate during:

- second updates
- minute updates
- rendering callbacks

Prefer:

- precomputed objects
- reusable buffers
- cached resources

---

## Architecture

Prefer small independent components.

Each component should have a single responsibility.

Example:

- Clock
- Date
- Battery
- Steps
- Weather
- Heart Rate

Components should not know about each other.

Use the inherited `Base.is_small` for widget font size selection and rendering.
Do not duplicate this state in subclasses; layout and widgets share the same field.

All settings named Auto use `-1`. Preserve the stored IDs of other options
when changing shared option enums.
Shared `Options` assigns automatic IDs from CRC32 of the exact enum name in
the range `0x40000000`–`0x7fffffff`; `AUTO = -1` and `NONE = 0` stay explicit.
Keep the algorithm and existing names stable: renaming changes persisted IDs.
Generation rejects collisions. Extra widget IDs use these values directly,
without an offset based on the number of data metrics.

Color settings outside the Global group may select Global (`-1`). Resolve that
choice against the matching Global color when constructing the widget, so
rendering uses a concrete color. Metric Width offers None (stored as `0`) to hide the numeric value while retaining the selected
icon/gauge and normal label handling. Skip number formatting and reserve no
numeric width in that mode. Metric Width uses `-1` for Auto; resolve it
once from the data object's default width when constructing the metric.

---

## Code style

Prefer:

- readable code
- explicit naming
- short functions
- immutable values where practical

Use named Boolean constants for literal arguments that select rendering or
layout options, such as `Render.HIDE_LABEL` or `Render.SHOW_LEFT`. Keep field
initializers as `true` / `false`; a named assignment already explains its meaning.

For equality comparisons involving instance state, keep `self.<field>` on the
left. For ordered comparisons, use only `<` or `<=`, with the larger value on
the right.

Avoid:

- deeply nested logic
- inheritance unless necessary
- generic abstractions without measurable benefit

---

## Optimisation policy

Never optimise blindly.

When suggesting optimisation:

1. explain why
1. estimate impact
1. mention trade-offs

Do not introduce complexity for negligible gains.

---

## Garmin-specific considerations

Always remember:

- CPU time affects battery life.
- Draw calls are expensive.
- Memory is limited.
- Some devices have different display sizes.
- AMOLED and MIP64 displays may behave differently.
- Connect IQ APIs vary between SDK versions.

If proposing API usage, verify compatibility.

The manifest supports multiple device families and has a minimum API level of
3.4.0. Changes to layout or API usage must preserve that compatibility and
consider at least one representative MIP64 and AMOLED device where applicable.
`data/devices` catalogs all SDK devices in Watches/Wearables with watch-face
support, including devices below the manifest API minimum. AMOLED support
includes fully round screens meeting the manifest API minimum. Catalog membership
does not imply app support; the manifest product list defines supported devices.
Before adding a manifest product, confirm its ID has an installed SDK device
`compiler.json` with watch-face support. SDK device-reference documentation alone
does not establish that the compiler accepts the device qualifier.

---

## Documentation

Document features or changes that affect architecture, battery or rendering
behaviour, settings, or user-visible behaviour.

Documentation should explain:

- why
- not only how

Examples are preferred.

---

## Testing

When changing behaviour:

- consider edge cases
- verify different display sizes
- verify different update intervals

If something cannot be tested automatically, explain how to test it manually.

Do not run the project build or the Connect IQ simulator in this environment;
both are known to fail here. Non-Connect-IQ checks, including `make test`, may
be run when relevant and when their dependencies are available.

---

## Git

Prefer small commits.

One logical change per commit.

Avoid large refactors mixed with feature work.

---

## AI agent behaviour

Before implementing anything:

- inspect existing architecture
- follow existing naming conventions
- minimise code churn

Do not rewrite working code without a clear benefit.

If a request conflicts with existing architecture,
explain the conflict before changing anything.

Always prefer incremental improvements.

---

## Keeping these instructions current

Treat this file as the durable, repository-wide record of working agreements.
When a discussion or implementation establishes a clear rule that is likely to
matter in future tasks, update `AGENTS.md` as part of the same change. Examples
include supported devices, verification constraints, generation workflows,
performance decisions, and established architectural conventions.

Do not add temporary task details, unresolved ideas, or user-specific secrets.
If it is unclear whether a new detail is a durable project rule, ask before
adding it.

---

## Performance review checklist

Before submitting code, verify:

- unnecessary redraws
- repeated calculations
- allocations inside update loop
- repeated resource loading
- expensive string operations
- duplicated rendering logic

---

## Website

The repository documentation is published on the project website.

TopOuter and BottomOuter are independently configurable widget slots. Both can
show battery information or dawn/dusk information with sun or moon icons.
Website hotspots for these slots should describe the available widgets and
remain separate from the middle metric hotspots.
Keep the middle website hotspots clear of their outer widgets. Size outer
hotspots for their content; the top widget can be taller than the bottom one.
Keep the side hotspots within the clock's vertical bounds so they do not reach
the date row. Place the side and clock hit areas edge to edge, without overlap.
The website shows one representative setting for each repeated metric, gauge
and status group. Label its index `N` and render it as an italic variable so the
example does not imply slot 1 only.

Documentation should therefore:

- be Markdown
- be readable
- include diagrams where useful
- explain design decisions

---

## Build system

The preferred build system is Makefile.

Keep the `make help` target and argument formatting aligned with the website,
CV, and chiroptera Makefiles; phase0 may extend the shared sections with its
device and build-mode listings.

Avoid introducing shell scripts unless they provide clear value.

Keep build steps reproducible.

All Python-based targets use one `.venv` and install the complete
`requirements.txt` dependency set. `make clean` removes the build and site
outputs, fetched site UI cache, virtual environments, Python caches, and root-level
`*.egg-info` metadata.

The release optimizer is pinned in `package-lock.json`; install its Node
dependencies with `npm ci` before producing a release build.

`manifest.xml.tmpl` is the shared source for developer, alpha, beta and release
manifest files. `make build` defaults to the developer PRG. `make alpha`,
`make beta` and `make iq` export separate IQ packages in release mode and
reject an explicit different `MODE`; developer has no IQ package. Generated
manifests and their selecting Jungle files live in
`build/manifests/`. Do not reuse a channel's application ID for another Store
listing. `make store` creates release artwork at `build/store/`, copies all
normal screenshots and only the data-rich AoD screenshot from
`site/assets/screenshots/`, and creates labeled alpha and beta icons, heroes
and data-rich covers in its channel subfolders.
Because manifests are generated outside the repository root, `monkey.jungle`
must explicitly anchor `base.sourcePath` and `base.resourcePath` to root source
and resource directories; SDK defaults would resolve against the manifest.

`make screenshots` generates `build/store/icon_128.png` and
`build/store/icon_512.png`, plus configured normal and AoD watch-face screenshots
in `site/assets/screenshots/` (named `<scenario>.png` and
`<scenario>-aod.png`). The Garmin Store requires a separate 500 x 500 icon.
Both `make store` and `make screenshots` also generate
`build/store/icon_128_amoled.png` using AMOLED regular digit styles. Its dedicated
Makefile target runs without the simulator.
Screenshot PNGs stay in Git because capturing them requires the simulator.
Screenshot capture is incremental: source code, resources, settings, scenario
definitions and generator changes must invalidate its build stamp.
`make store_assets` recreates both icons and `build/store/hero.png` without the
simulator. The hero pairs
the data-rich normal and AoD screenshots at 1440 x 720. The small AoD face
retains its native 280 x 280 size; the main face is scaled exactly 2x to keep
pixels even.
`make site` copies source assets into `build/site/` and generates the favicon
and both `fr955` overlays directly in that publishable output.
AoD capture temporarily forces `isNightMode_()`
while compiling each mode and restores `source/phase0/view.mc` immediately.
The screenshot generator starts one simulator per invocation and loads each
scenario's PRG into that running simulator, including when it changes devices.
After loading each PRG, the generator uses the simulator's Reset All App Data
command and waits for the watch face to restart before capturing; the simulator
otherwise retains application properties between loads.
Shared simulator process lifecycle helpers live in
`scripts/utils/simulator_process.py`. On Linux, start the SDK's `simulator`
binary directly: its `connectiq` shell launcher does not exec the child, so
terminating the launcher can leave the simulator running.
Screenshot capture tracks the X11 window
IDs opened during its run and closes only those windows.
`make smoke` and `make smoke_test` must stop on the first application error or
failed test, clean up their processes, and exit with a nonzero status.
Screenshot scenarios live in
`data/screenshots.py`; device, app-property overrides, and gallery title,
description and alt text belong together there. Simulator time display and
units display also belong to each scenario; the defaults are 24 hour and
metric. Apply them after loading each PRG and before resetting app data.
`make site` generates
`screenshots-data.js` from that metadata for the website gallery. Scenario
overrides must not change `data/settings/data.py`. Screenshot capture
requires a graphical X11 or XWayland session, the Connect IQ Simulator,
`wmctrl` and `xdotool`. On Wayland, the screenshot workflow starts the
simulator through GTK's X11 backend for window control and native capture.

Do not run the project build or the Connect IQ simulator in this environment.
Both are known to fail here, so they do not provide useful verification.

---

## Communication

When explaining code:

- explain reasoning first
- implementation second

When uncertain:

do not guess

instead explain assumptions.

## Display font profiles

Font outputs live in `resources/fonts/mip/generated/` and
`resources/fonts/amoled/generated/`; do not edit them by hand. `build/resources.jungle`, generated by
`scripts/generate_resources_jungle`, chooses exactly one font profile from the manifest-supported device's
`ScreenType`, independently of memory class. AMOLED increases each grid step
and foreground dot weight by one; thin dots and the shadow offset stay 1 px.
Other screen types use the original MIP profile. Preserve resource IDs across
profiles and select `Fonts.SPACING_*` with the `display_mip` / `display_amoled`
source annotations at compile time. Keep device memory and font resource paths
and exclusions together in this generated Jungle; `monkey.jungle` contains only
shared settings. Do not scale fonts during rendering.

Name physical font styles `STYLE_1` through `STYLE_4`, with `_BOLD` and `_THIN`
suffixes for weight variants. The number denotes the grid step in pixels.
Keep logical roles (`regular`, `regular_thin`, `small`, `tiny`) and generated
resource names separate from physical style names; map roles explicitly per
display profile in the font generator.

## Display mode lifecycle

Partial-update callbacks, their power-budget callback and update-mode state
compile only with `display_mip`. AMOLED retains sleep/wake update requests for
visible faces and renders normal seconds without partial-update budget checks.
Keep the Seconds widget shared because awake rendering uses it on both profiles.

Compile display-mode callbacks, constants, state and mode-reading helpers only
with `display_amoled`. MIP uses a single `is_visible_` flag and cached night
mode; its lifecycle must not include the AMOLED handler, whose code footprint
can exceed the 96 KiB budget on Descent Mk2S. Shared update paths use
profile-specific `isVisibleMode_()` and `isMinimalMode_()` helpers. The current
manifest supports only MIP64 and AMOLED. If LCD support is added, separate
display-mode capability from font profile before selecting its lifecycle.

`App.onDisplayModeChanged()` forwards to the view. Read display mode only in
that handler and when the face is shown, guarding `System.getDisplayMode()`
for API 3.4.0 compatibility. Keep display state independent of sleep/wake and
partial-update budget state. Store the system mode or HIDDEN in `display_mode_`
and derive minimal rendering from it and cached night mode; do not store a
second effective display mode or separate visibility flag on AMOLED. HIDDEN ignores
display-mode notifications until onShow reads the current system mode again.
Minimal is selected by night mode or LOW/AoD; HIDDEN and OFF skip update
callbacks, update requests and touch handling. Returning from OFF or changing
normal/minimal invalidates the visible face; repeated notifications must not
request redundant redraws. AMOLED minimal uses black regardless of the chosen
background; other modes and display types retain the configured background.
Use generated `Display.IS_AMOLED` from `source/generated/display.mc`, selected
by the display profile annotations, to
identify AMOLED independently of display-mode API availability on LCD devices.
Select the two `updateMinimal_()` implementations with `display_mip` and
`display_amoled` annotations at compile time. Keep the shifting helper and
generated offset module AMOLED-only, so MIP renders directly without offsets
or runtime display-profile branches.
Keep `isNightMode_()` available for the screenshot generator's mode override.

AMOLED minimal minute offsets are computed during font generation from the
generated atlases and minimal-rendering shadows, then written to
`source/generated/burn_in.mc`. Do not hardcode or manually edit the cycle.
Keep `scripts/utils/burn_in.py` masks aligned with minimal font, shadow and
battery rendering changes. Generation rejects cycles that cannot fit within
±2 px and four minute phases. Mask checks do not replace device luminance,
layout or heat-map validation.
