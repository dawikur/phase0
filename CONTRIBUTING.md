# Contributing to phase0

Bug reports, fixes, and improvements are welcome. Please open an issue before
starting a large feature or architectural change so we can agree on the scope.

## Getting started

Follow the [README](README.md#getting-started) to set up the development
environment. Read [AGENTS.md](AGENTS.md) for the project's coding, rendering,
memory, and device compatibility rules.

Keep changes focused and separate unrelated refactors. Rendering performance
and battery use matter: avoid allocations during rendering and second/minute
updates. Edit generator inputs or generators rather than generated outputs,
and use the Make targets to regenerate resources.

## Reporting bugs

Describe what happened, what you expected, and how to reproduce the issue.
For watch-face issues, include the device model, app version, relevant settings,
and whether the issue occurs while awake or in low-power mode. Add screenshots
or logs when useful, removing personal information first.

## Before opening a pull request

Run:

```sh
make lint
make test
```

`make lint` may reformat files; review the resulting diff. Tests require 100%
functional/mock coverage. Add meaningful tests for behavior changes and edge
cases; keep the coverage threshold intact.

In your pull request, explain the problem, the resulting behavior, and how you
validated the change. For rendering or device-specific changes, include the
devices and display modes checked, screenshots where useful, and any impact on
memory, rendering time, or battery use. State which checks you could not run.
