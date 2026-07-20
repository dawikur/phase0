# AGENTS.md

# phase0

`phase0` is a Garmin Connect IQ watch face focused on minimalism, performance and battery efficiency.

This document describes how AI agents should work within this repository.

---

# Project goals

Priority order:

1. Correctness
2. Rendering performance
3. Battery life
4. Maintainability
5. Simplicity
6. Small binary size

Never sacrifice performance for abstraction.

---

# Technology

- Garmin Connect IQ
- Monkey C
- Makefile build
- GitHub
- Cloudflare Pages documentation

Documentation is generated separately and copied into the website repository.

---

# Repository map

- `source/phase0/` — application lifecycle, view and layout
- `source/widgets/` — reusable watch-face UI components
- `source/data/` — individual data metrics and their formatting
- `source/utils/` — rendering, caching, runtime and data providers
- `data/` — inputs for generated resources and settings
- `resources/` — source resources and generated resource definitions

Do not edit generated files by hand. In particular, treat
`source/generated/`, `resources/generated/` and `docs/settings-data.js` as
build outputs; change their source data or generator instead.

---

# Philosophy

The watch face should feel native.

Avoid solutions that:

- allocate memory every update
- redraw unnecessarily
- introduce hidden complexity
- require excessive abstraction
- use client-side caches or persistent browser storage for website state

Prefer explicit code over clever code.

---

# Rendering rules

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

# Memory allocations

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

# Architecture

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

# Code style

Prefer:

- readable code
- explicit naming
- short functions
- immutable values where practical

Avoid:

- deeply nested logic
- inheritance unless necessary
- generic abstractions without measurable benefit

---

# Optimisation policy

Never optimise blindly.

When suggesting optimisation:

1. explain why
2. estimate impact
3. mention trade-offs

Do not introduce complexity for negligible gains.

---

# Garmin-specific considerations

Always remember:

- CPU time affects battery life.
- Draw calls are expensive.
- Memory is limited.
- Some devices have different display sizes.
- AMOLED and MIP displays may behave differently.
- Connect IQ APIs vary between SDK versions.

If proposing API usage, verify compatibility.

The manifest supports multiple device families and has a minimum API level of
3.4.0. Changes to layout or API usage must preserve that compatibility and
consider at least one representative MIP and AMOLED device where applicable.

---

# Documentation

Document features or changes that affect architecture, battery or rendering
behaviour, settings, or user-visible behaviour.

Documentation should explain:

- why
- not only how

Examples are preferred.

---

# Testing

When changing behaviour:

- consider edge cases
- verify different display sizes
- verify different update intervals

If something cannot be tested automatically, explain how to test it manually.

Do not run the project build or the Connect IQ simulator in this environment;
both are known to fail here. Non-Connect-IQ checks, including `make test`, may
be run when relevant and when their dependencies are available.

---

# Git

Prefer small commits.

One logical change per commit.

Avoid large refactors mixed with feature work.

---

# AI agent behaviour

Before implementing anything:

- inspect existing architecture
- follow existing naming conventions
- minimise code churn

Do not rewrite working code without a clear benefit.

If a request conflicts with existing architecture,
explain the conflict before changing anything.

Always prefer incremental improvements.

---

# Keeping these instructions current

Treat this file as the durable, repository-wide record of working agreements.
When a discussion or implementation establishes a clear rule that is likely to
matter in future tasks, update `AGENTS.md` as part of the same change. Examples
include supported devices, verification constraints, generation workflows,
performance decisions, and established architectural conventions.

Do not add temporary task details, unresolved ideas, or user-specific secrets.
If it is unclear whether a new detail is a durable project rule, ask before
adding it.

---

# Performance review checklist

Before submitting code, verify:

- unnecessary redraws
- repeated calculations
- allocations inside update loop
- repeated resource loading
- expensive string operations
- duplicated rendering logic

---

# Website

The repository documentation is published on the project website.

Documentation should therefore:

- be Markdown
- be readable
- include diagrams where useful
- explain design decisions

---

# Build system

The preferred build system is Makefile.

Avoid introducing shell scripts unless they provide clear value.

Keep build steps reproducible.

Do not run the project build or the Connect IQ simulator in this environment.
Both are known to fail here, so they do not provide useful verification.


---

# Communication

When explaining code:

- explain reasoning first
- implementation second

When uncertain:

do not guess

instead explain assumptions.
