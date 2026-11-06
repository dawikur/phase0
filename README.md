# phase0

Source repository for a Garmin Connect IQ watch face. For the product overview,
see the [phase0 website](https://dawikur.dev/phase0).

## Getting started

You need Python 3.10 or newer, Node.js 22, and the Garmin Connect IQ SDK.
The Makefile reads the active SDK from `~/.Garmin/ConnectIQ/current-sdk.cfg`
and creates `.venv`
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

## Ubuntu 22.04 development box

The Garmin Linux SDK depends on WebKitGTK 4.0, which is unavailable in newer
Ubuntu releases. Use the repository's [Distrobox manifest](distrobox.ini) to
keep those libraries in Ubuntu 22.04 while sharing the host desktop and home.
Install Distrobox and Podman (or Docker) on the host first. On an x86_64 host,
run these commands from the repository root:

```sh
distrobox assemble create --file distrobox.ini
distrobox enter phase0-ciq
```

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
on a watch, select its channel, for example `make build CHANNEL=beta`. To
create uploadable, release-mode IQ packages, run `make beta` or
`make iq` (`build/phase0.iq` for the public release). Run `npm ci` before these
release builds. The wrapper uses optimizer 1.2.7 to optimize Monkey C source
before compilation and calls `optimizeProgram()` afterward for binary
optimization. A failure in either stage fails the build. Direct npm and Python
dependencies use exact versions; `package-lock.json` also pins transitive npm
dependencies.

The manifest generator assigns a stable ID to each channel using the shared
`manifest.xml.tmpl`. Developer is for PRG testing; beta is a private Garmin
Beta App; release is the public watch face and uses the former beta listing
ID (`acbbdc44-3573-4970-ab72-978ab5656212`). Developer and beta retain their
separate IDs.
The website's Connect IQ links use an independent Store listing ID, which
does not need to match the release manifest ID.

`make store` generates one shared artwork set in `build/store/` for beta and
release, without channel labels.

The website's [watch frame](site/assets/watch-frame.svg) is an original,
generic illustration licensed under this repository's MIT license. It contains
no Garmin SDK artwork.
