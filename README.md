# phase0

phase0 is a minimal, battery-efficient Garmin Connect IQ watch face.

## Project documents

- [TODO.md](TODO.md) — compact product and technical backlog.
- [RELEASE.md](RELEASE.md) — checklist for preparing and publishing a release.
- [CHANGELOG.md](CHANGELOG.md) — release history.

The changelog starts with the first published release.

## Smoke test

Run `scripts/smoke` to build and launch the release watch face for every
device declared in `manifest.xml`. The script starts one simulator and loads
each device build into it in sequence. Each watch face remains running for ten
seconds after it reports that application initialization is complete. The
script fails if that report does not arrive within 30 seconds.
If Connect IQ reports an application crash, the script stops immediately and
keeps the simulator log in the terminal for diagnosis.
Set `--simulator-duration` to change that interval, for example
`scripts/smoke --simulator-duration 20`.

Run `make smoke_test` to build the test variant and run all tests in the
simulator. To run only one test, select it explicitly with
`make smoke SMOKE_MODE=test SMOKE_TEST=SmokeDataTest`.
