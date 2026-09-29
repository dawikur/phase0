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

---

## Code style

Prefer:

- readable code
- explicit naming
- short functions
- immutable values where practical

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
`scripts/utils/simulator_process.py`. Screenshot capture tracks the X11 window
IDs opened during its run and closes only those windows.
Screenshot scenarios live in
`data/screenshots.py`; device, app-property overrides, and gallery title,
description and alt text belong together there. Simulator time display and
units display also belong to each scenario; the defaults are 24 hour and
metric. Apply them after loading each PRG and before resetting app data.
`make site` generates
`screenshots-data.js` from that metadata for the website gallery. Scenario
overrides must not change `data/settings/settings.py`. Screenshot capture
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
