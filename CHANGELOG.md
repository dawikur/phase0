# Changelog

All notable changes to phase0 are documented in this file.

The project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- Exclude buffered-rendering code from low-memory devices and touch handlers
  from devices without touch screens; keep partial-update budget handling MIP-only.
- Compile display-mode handling only for AMOLED, reducing the MIP code
  footprint implicated in out-of-memory crashes on Descent Mk2S.
- Start the Linux simulator directly so smoke checks close the actual simulator
  before the next check starts.
- Guard unavailable battery-life estimates on devices such as Forerunner
  945 LTE. The remaining-days metric is unavailable when no estimate exists;
  battery widgets fall back to the battery percentage.
- Treat climbed and descended floors as unavailable on devices that do not
  expose those activity fields, preventing startup and smoke-test errors on
  devices such as Approach S50.

## [0.1.0]

### Initial release

- Initial release.
