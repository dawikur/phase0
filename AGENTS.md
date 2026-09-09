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

---

## Repository map

- `source/phase0/` — application lifecycle, view and layout
- `source/widgets/` — reusable watch-face UI components
- `source/data/` — individual data metrics and their formatting
- `source/utils/` — rendering, caching, runtime and data providers
- `data/` — inputs for generated resources and settings
- `resources/` — source resources and generated resource definitions
- `README.md` — project entry point and links to project documents
- `TODO.md` — compact product and technical backlog
- `RELEASE.md` — release preparation and publishing checklist
- `CHANGELOG.md` — release history

Do not edit generated files by hand. In particular, treat
`source/generated/`, `resources/base/generated/`, `build/site/settings-data.js` and
`build/site/devices-data.js` as
build outputs; change their source data or generator instead.

Memory-specific resources belong in `resources/memory/low/`,
`resources/memory/medium/` or `resources/memory/high/`. Their device mapping and
`memory_low`, `memory_medium` and `memory_high` source exclusions are generated
from `manifest.xml` and `data/devices`; inverse annotations
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
