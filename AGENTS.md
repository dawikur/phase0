# phase0

Garmin Connect IQ watch face, Monkey C. Priorities: correctness, rendering
performance, battery, maintainability, simplicity, binary size. Never trade
performance for abstraction.

## Working rules

- Inspect architecture/naming first. Keep changes focused; separate refactors.
  Explain architectural conflicts, assumptions and performance trade-offs first.
- **Keep AGENTS.md short; do not add everything or update it after every task.**
  Only durable, repository-wide rules preventing recurring mistakes belong here.
  Merge/replace duplicates. Put details, workflows and findings near code or in
  dedicated docs; no task logs, temporary notes, unresolved ideas or secrets.
  Ask if lasting relevance is unclear. README: entry point; TODO: backlog;
  CHANGELOG: releases.
- Edit inputs/generators, never generated outputs (`source/generated/`, resource
  `generated/`, `build/site/*-data.js`). Prefer reproducible Make targets.

## Rendering and memory

- No allocations in second/minute updates or rendering. Cache calculations, text,
  layouts/resources; reuse buffers. Use dirty rectangles; full redraw only for
  complete visual changes/wake. Clear buffers to configured background.
- Release old widgets from layout/refresh/battery lists before replacement;
  never retain two widget trees or a full settings tree. Finish layout/update
  before partial rendering. Inherit `Base.is_small`.
- Group `Properties.Get*()` reads at startup/settings changes. Anchor inner rows
  as if all three exist; middle/outer share remaining space. Center gauge dots
  over the full bar (right center pixel for even widths).
- Memory/display/touch are independent compile-time profiles; annotations use
  underscores. Buffers, explicit style and all forecast state require
  `memory_not_low`. Low uses direct rendering, Auto style and cached current weather
  with retries/clock rollback. Preserve allocation guards/fallback; recheck forecast
  eligibility after layout allocation each refresh.
- Select one memory-independent `ScreenType` font profile and one memory/display
  `ICONS` font with explicit settings/properties XML; no recursive variants/scaling.
  Preserve IDs, compile-time spacing and `STYLE_1`–`STYLE_4` mapping. AMOLED grid/
  foreground dots add 1 px; thin dots/shadows stay 1 px. Unsupported icons reserve
  no space; low has general icons only.

## Devices and lifecycle

- Minimum API 3.4.0; verify APIs and representative MIP64/AMOLED sizes/intervals.
  Manifest defines support, not `data/devices`; new devices need SDK watch-face
  support. AMOLED must be round; use `Display.IS_AMOLED`, not API availability.
  LCD needs separate mode/font profiles. Device paths/exclusions belong in
  `scripts/generate_resources_jungle`; shared settings in `monkey.jungle`.
- Touch comes from SDK `display.isTouch` (unknown `None`); reject unknown supported
  capabilities. Press handlers/complication state require `input_touch`; shared APIs
  retain guards. Non-touch `open()` returns false and keeps no complication state.
- `display_mip` alone owns partial callbacks/budget/update state; AMOLED awake
  seconds bypass budgets. Share Seconds and visible sleep/wake requests.
- `display_amoled` alone owns mode callbacks/state/readers. App forwards changes to
  view; read system mode only there/onShow with API guards. Keep mode/HIDDEN in
  `display_mode_`; derive minimal from it/cached night mode, without duplicate state.
  HIDDEN ignores notifications until onShow; HIDDEN/OFF skip callbacks/updates/touch.
  OFF return/normal-minimal transitions invalidate; repeated notifications do not.
- Night/LOW/AoD means minimal (AMOLED black, otherwise configured background).
  Keep sleep/budget separate; compile-time `updateMinimal_()`, AMOLED-only shifts.
  Preserve capture override `isNightMode_()`. Generate burn-in offsets from atlases/
  minimal shadows, never hardcode cycles; align masks with rendered elements.
  Limit ±2 px/four minute phases; still verify device luminance/layout/heat maps.

## Settings and metrics

- Persistent IDs: `Options` = CRC32(exact enum name), `Datum.value` = CRC32(`DATA_` +
  exact metric name), range `0x40000000`–`0x7fffffff`. Preserve names/algorithm,
  including AUTO/NONE/GLOBAL; reject collisions. Filtered/combined enums copy IDs;
  smoke tests use real IDs. No beta legacy migration.
- Use `Properties.AUTO/NONE/GLOBAL`; widths 1–10 are literal. Resolve Auto widths/
  Global colors at construction. Width 0 removes numeric formatting/space only.
  Empty reserves three digits without drawing/refresh regardless of Width/Style;
  disabled slots disappear. Status Empty reserves a transparent icon; None omits it.
- Goals use one `ActivityMonitor.getInfo()` snapshot; limits precede Auto layout.
  HR zones refresh at most once/epoch minute independently of readings; missing
  goals/zones clear limits. Status uses one device-settings snapshot/refresh and
  cached bitmask, no metric sources; keep `data_status` parsing independent of options.
  Declare `data_icon`/`data_gauge` on classes, never inspect constructors.

## Code and validation

- Named Boolean rendering/layout arguments; literal field initializers. Equality:
  `self.<field>` left. Ordering: `<`/`<=` only, larger value right. Infer locals;
  cast expressions, no typed locals.
- `Test.assert` for Boolean/null/inequality; `assertEqual` only for non-null values.
  Test subclasses access hidden methods via `self` with forwarding constructors.
  Annotated methods are logger-taking runner entries, not helpers.
- Test observable behavior, not source fragments/snapshots/private state/sequences.
  Execute generated code/website scripts; parse XML/JSON contracts. Lint style.
  Mandatory `make test`: 100% functional/mock coverage; never lower thresholds or
  exclude code. Cover edges/sizes/intervals; report unavailable checks.
- **Never run project builds or Connect IQ simulator here: both fail.**
  Non-Connect-IQ checks, including `make test`, are allowed with dependencies.

## Tooling and assets

- One `.venv`; exact direct npm/Python pins, committed npm lockfile, local formatter
  hooks; release `npm ci`. Keep outputs/caches clean. Container setup must not edit
  shared home dotfiles; SDK installation/license acceptance stays manual.
- Require source optimization AND `optimizeProgram()`; fail on post-build failure.
  Preserve 96 KiB optimizer options and returned compiler command/sidecars.
- Generate channel manifests from `manifest.xml.tmpl`; use repo-root Jungle paths.
  Default: developer PRG; release channels: distinct packages/app IDs. Reject
  conflicting MODE; never reuse Store app IDs.
- Commit screenshot PNGs. `data/screenshots.py` owns captures/24h/metric overrides;
  never change settings data for captures. Invalidate stamps on input changes.
  Capture tooling restores `view.mc` after AoD overrides, uses the shared simulator
  process helper, resets/restarts each PRG and closes only owned windows. Fail fast,
  clean processes; simulator tests require passing summary and shutdown.
  These rules do not authorize running simulator here.
- Website: no client caches/persistent storage. Keep middle clear; outer hotspots
  fit content independently, within clock height/away from date, without overlaps.
  Describe battery/dawn/dusk; repeated settings use italic `N`, not slot 1.
