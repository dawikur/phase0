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
and run every supported device in the Connect IQ simulator.

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
