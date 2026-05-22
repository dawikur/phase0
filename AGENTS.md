# Repository Guidelines

## Project Structure & Module Organization

This is a Garmin Connect IQ watch-face project. Source lives in
`source/`: `main/` has clock/status components, `phase0/` has view/rendering
logic, `complications/` has display elements, and `data/` has metric providers.
XML resources are in `resources/`, including generated base files in
`resources/base/` and settings in `resources/settings/`. Python generation
tooling is split between executable scripts in `scripts/` and font/icon models
in `fonts/`. Static inputs include `manifest.xml`, `monkey.jungle`, `assets/`,
and `docs/`. Build output goes to `build/`; do not edit it directly.

## Build, Test, and Development Commands

- `make build` or `make b`: generate resources and compile for `DEVICE=fr955`.
- `make build_test` or `make bt`: compile with Monkey C unit-test support.
- `make simulate` or `make s`: start the Connect IQ simulator and run the app.
- `make simulate_test` or `make st`: run test builds in the simulator.
- `make resources` or `make r`: regenerate `resources/base/drawables.xml` and
  `resources/base/fonts.xml`.
- `make test` or `make t`: run pytest.
- `make clean` or `make c`: remove generated build/resource outputs.

Override Make variables as needed:
`make build DEVICE=fenix7 MODE=release V=1`.

## Coding Style & Naming Conventions

Keep Monkey C modules organized by feature under `source/` and follow existing
patterns: lowercase filenames and providers in `source/data/`. Python code is
formatted with Black and isort; `pyproject.toml` enables strict mypy checks. Use
4-space indentation for Python and the surrounding style for Monkey C and XML.
Change generated resources through `fonts/` or `scripts/`.

## Testing Guidelines

Use `make test` for Python tooling tests and `make build_test` plus
`make simulate_test` for Connect IQ test builds. Add pytest tests named
`test_*.py` near the code they validate or in a future `tests/` package. For
rendering, settings, fonts, or data providers, verify resources and a simulator
run for the target device.

## Commit & Pull Request Guidelines

History uses short, imperative subjects such as `Add smaller digit font`
and `Extract icons to a separate data file`. Keep commits focused and avoid
mixing generated output with unrelated source changes. Pull requests should
include a summary, affected devices or settings, commands run, and screenshots
or simulator captures for visible watch-face changes. Link issues or TODO items
when applicable.

## Security & Configuration Tips

The Makefile reads the Connect IQ SDK path from
`~/.Garmin/ConnectIQ/current-sdk.cfg` and expects a private key at
`~/Documents/developer_key`. Do not commit private keys, local SDK paths,
generated `build/` artifacts, or simulator state files.
