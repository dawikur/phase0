# phase0 release checklist

Follow in order. `fr955` is the default device. Run Connect IQ builds and
simulator checks on a computer with a working SDK and simulator.

## 1. Prepare

- [ ] Review release commit, `CHANGELOG.md`, setting compatibility, and clean
  working tree.
- [ ] Check SDK, `CONNECTIQ_DEVELOPER_KEY`, Node.js 22, and Python dependencies.
- [ ] `npm ci` - pinned release optimizer.
- [ ] `make lint` - inspect any formatting changes.
- [ ] `make test` - rerun if lint changed files.
- [ ] `git diff --check` and `git status --short`.

## 2. Build and automated checks

- [ ] `make smoke_test` - test builds on all supported devices.
- [ ] `make smoke` - release builds on all supported devices.
- [ ] `make alpha|beta|iq` - package for the chosen Store channel.
- [ ] `make screenshots` (simulator)
- [ ] `make store` - review `site/assets/screenshots/` and `build/store/`.

## 3. Test Store installation on a watch

- [ ] **Test listing:** Upload `build/phase0-alpha.iq` or `build/phase0-beta.iq`
  to its existing listing; check validation, devices, notes, and artwork.
- [ ] **Installation:** Install through Connect IQ, sync the watch, and select
  phase0.
- [ ] **Startup:** Starts without errors; default clock, date, weather, metrics,
  gauges, status icons, and outer widgets fit the screen.
- [ ] **Time updates:** Seconds and at least two minute changes work; no flicker
  or leftover digits.
- [ ] **Watch data:** Steps, heart rate, and battery agree with the watch; steps
  update after a walk.
- [ ] **Weather and sun times:** Weather and sunrise/sunset appear after phone
  sync when data is available; missing data leaves a usable face.
- [ ] **Colors:** Global colors and colors set to `Global` update and remain
  readable.
- [ ] **Layout:** Dense and minimal layouts fit; hidden metrics/gauges/status
  icons leave sensible spacing.
- [ ] **Metric width:** A metric's `Auto` and manual widths render without
  clipping.
- [ ] **Outer widgets:** Top and bottom can independently show battery,
  sunrise/sunset, or nothing.
- [ ] **Time format and units:** 12/24-hour time, AM/PM, and available unit
  settings match the watch.
- [ ] **Status icons:** Enabled phone, alarm, and notification icons respond to
  state changes; disconnect and reconnect the phone.
- [ ] **Sleep hours:** The simplified clock/status/battery view appears; the
  full view returns afterward.
- [ ] **Settings persistence:** Leaving and returning to the face, then
  restarting the watch, preserves the face and settings.
- [ ] **Full-day use:** Check the date change, data refresh, stability, and
  battery use against a comparable day with the usual face.
- [ ] **AMOLED / AoD:** If affected, repeat display and sleep checks on a
  compatible AMOLED watch.

## 4. Publish

- [ ] Upload `build/phase0.iq` to the **existing public** listing; keep each
  channel's app ID with its listing.
- [ ] Check Store validation, supported devices, release notes, localizations,
  icons, screenshots, preview, and approval status.
- [ ] After publication, install/update from the public listing through Connect
  IQ and repeat the watch checks in section 3.
