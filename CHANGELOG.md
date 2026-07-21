# Changelog

All notable changes to phase0 are documented here.

The project uses [Semantic Versioning](https://semver.org/):

- Increment the patch version for fixes that preserve settings and behaviour.
- Increment the minor version for backwards-compatible features or settings.
- Increment the major version when an upgrade requires user action or changes
  existing behaviour incompatibly.

## [Unreleased]

### Added

- Release checklist, continuous test workflow and reproducible release-build
  dependency metadata.

### Changed

- Weather data retries every minute while a current-condition field is missing,
  then returns to hourly refreshes once the snapshot is complete. Cached values
  remain available during recovery. Unchanged weather and sensor values refresh
  only their cache timestamp at most once an hour, while forecast persistence
  stays hourly to limit storage and battery use. Empty cache reads no longer
  issue cleanup writes.
