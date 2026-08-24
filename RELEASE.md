# Release checklist

Before publishing a release, complete and record the following checks.

## Watch face

- [ ] Run `make test`.
- [ ] Test the release build on representative devices: a small MIP64 display
      and larger MIP64 display.
- [ ] Check normal mode, sleep/AoD mode, wake-up and power-budget fallback.
- [ ] Check every supported language and settings screen for clipped or
      unreadable text.
- [ ] Check missing permissions, unavailable sensors, zero values and other
      unavailable data cases.
- [ ] Confirm that the supported products in `manifest.xml` are intentional.

## Connect IQ Store

- [ ] Build the final signed `.iq` package using the established developer key.
- [ ] Keep the developer key safe; future Store updates must use the same key.
- [ ] Prepare the Store description, screenshots and supported-device details.
- [ ] Document the requested permissions and data handling. State explicitly
      whether any data leaves the device.
- [ ] Upload the package for Garmin review and test the Store preview.

## Website

- [ ] Run `make site` before copying documentation to the website repository.
      It generates `site/settings-data.js`, the icon and device overlays, which
      are intentionally not tracked in Git.
- [ ] Check the deployed page on desktop and mobile in light and dark themes.
- [ ] Check both Normal and AoD previews, feature hotspots, the MIP64 palette
      page and every external link.
- [ ] Replace the pending Connect IQ link with the Store listing after approval.
- [ ] Provide a visible support route and privacy information.

## Release record

- [ ] Assign a version, create an annotated Git tag and publish release notes.
- [ ] Record tested devices, SDK/optimizer versions and known limitations in
      the GitHub release notes.

Use Semantic Versioning for release tags.
