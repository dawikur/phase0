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
- [ ] Prepare Store screenshots from real watch-face renders for the supported
      MIP devices. Do not use AMOLED renders: the products in `manifest.xml`
      are MIP models.
- [ ] Document the requested permissions and data handling. State explicitly
      whether any data leaves the device.
- [ ] Upload the package for Garmin review and test the Store preview.

### Store hero image and icon

- [ ] Prepare an optional **hero image** at 1440 x 720 px. Use a wide,
      uncluttered composition with a large, genuine phase0 MIP face render and
      a short message such as “Your data. Your layout.” The hero should explain
      the watch face's data-rich customization at a glance; avoid showing a
      physical watch or implying support for AMOLED devices. If the hero has
      text, prepare localized versions for the Store languages or use no text.
- [ ] Prepare the **Store app icon** at 500 x 500 px in sRGB. Use a simple,
      recognizable face preview or clock mark on a solid, non-black background.
      Keep about 10 px of padding around the central artwork, avoid small text
      and fine details, and do not use Garmin branding. The icon needs to remain
      legible in small search results and app lists. Run `make screenshots` to
      generate `site/assets/icon_big.png` from the generated project icon.
- [ ] Keep the Store icon distinct from the on-device launcher icon asset.
      Garmin's brand guidance specifies 128 x 128 px for an optional on-device
      icon; check the upload form for the exact assets requested for this
      release.

### Description

> phase0 is a clean, customizable watch face built to keep useful information
> easy to read.
>
> Put the time first, then choose the details that matter to you. Add activity
> and health metrics, weather, battery information, sunrise and sunset, or
> status icons. Pick your colors and decide which data appears in the available
> areas.
>
> Make the layout yours
>
> - Choose colors for the background, text, accents and clock.
> - Add metrics such as heart rate, steps, floors, stress, Body Battery,
>   calories and recovery time.
> - Show weather details such as temperature, rain chance, UV index and wind.
> - Add battery, alarm, phone connection and notification indicators.
> - Choose sunrise and sunset information, with sun or moon icons.
>
> Designed to adapt
>
> phase0 measures the available screen space and adjusts the layout to fit.
> Depending on the device and selected fields, it can resize text, rearrange
> the spacing or omit lines that do not fit. Smaller screens can show a simpler
> face; larger screens can fit more information.
>
> The watch face is designed with efficient updates in mind. Some data depends
> on your device, Garmin Connect, available sensors and permissions, and may
> not be available on every watch.
>
> Readable At A Glance
>
> The large segmented clock stays dominant while secondary metrics keep their
> own lanes.
>
> Adaptive Color System
>
> Accent, foreground and background combinations keep the face readable across
> bright daytime use and low-distraction AoD viewing.
>
> Built For Small Screens
>
> The layout adapts to each watch screen and the widgets you choose, keeping
> icons, labels, values and gauges clear at a glance.

### Store screenshots

Use clean, device-free crops of the watch-face render. The screenshots should
show the face itself without a physical watch, bezel or promotional framing.
Use configurations that can actually be selected in the app, and keep data
values plausible. Prepare these views:

1 **Information-rich layout** — show the clock alongside several metrics,
   weather, status and battery indicators. This is the lead image and explains
   at a glance what phase0 can display.
2 **Reduced layout** — show fewer selected fields with more open space. This
   demonstrates that users can choose what appears on the face.
3 **Alternate color scheme** — keep a similar layout and change the accent
   colors. This makes color customization clear without asking viewers to
   compare different data sets.
4 **Compact-screen layout** — use a render from a small supported MIP device
   such as a 240 x 240 model. Pair it with a denser render from a larger
   supported MIP screen to show how the layout resizes or omits lines when
   available space changes.
5 **Optional sunrise/sunset view** — show the sun or moon indicator with the
   date and selected metrics, illustrating another configurable widget.
6 **Additional color and data combination** — use a neutral gray background
   with a different set of weather and activity metrics to show how the face
   combines configurable colors and data.

The layout comparison should use genuine renders at the relevant supported
screen sizes. A static screenshot cannot show the layout recalculating, so use
separate before/after images and a short caption if the Store allows captions.
Do not imply that each screenshot is a different device feature; the examples
show configurations and screen sizes supported by the same watch face. Check
that text, colors and line visibility match the MIP output.

The scenarios are configured in `data/screenshots.py`. Set each
scenario's device and property overrides there, then run `make screenshots` to
generate the icon at `site/assets/icon_big.png` and screenshots at
`site/assets/screenshots/`. Each scenario produces a normal image and an AoD
image named `<scenario>.png` and `<scenario>-aod.png`; the website's Normal/AoD
control switches the gallery between them. The screenshot generator forces
`isNightMode_()` to the corresponding value only during compilation and restores
the source file afterward. One simulator instance is reused for every scenario
in the run, with each scenario's PRG loaded in sequence. The home page displays
the screenshot gallery. Use `scripts/generate_screenshots --scenario <name>` to
capture one scenario.
Screenshot capture requires a graphical X11 or XWayland session, plus `wmctrl`
and `xdotool`. On Wayland, the generator starts the simulator through GTK's
X11 backend so its window can be controlled and its native screenshot command
can be automated.

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
