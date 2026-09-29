# phase0

phase0 is a minimal, battery-efficient Garmin Connect IQ watch face.

## Project documents

- [TODO.md](TODO.md) — compact product and technical backlog.
- [CHANGELOG.md](CHANGELOG.md) — release history.

The changelog starts with the first published release.

## Build channels

The default `make build` produces a device-specific developer PRG. Select a
different channel with `make build CHANNEL=alpha DEVICE=fr955` when testing a
Store identity on a device. Build uploadable packages with `make alpha`,
`make beta`, or `make iq` for the release `phase0.iq` package.
The developer channel has no IQ package target.
These three package targets always compile in release mode and reject an
explicit `MODE` value other than `release`.

`manifest.xml.tmpl` holds the shared product, permission, and language lists.
Make renders each channel's stable ID and name into `build/manifests/` before
compilation. Keep each ID assigned to its existing Garmin Store listing when
uploading updates: developer is for PRG testing, alpha is a private Garmin
Beta App, beta is a separate public test listing, and release is the public
watch face. Separate IDs keep installations and settings independent.

`make store` creates the release icons and hero in `build/store/` and copies
all normal screenshots plus the data-rich AoD screenshot from
`site/assets/screenshots/`. It also creates purple-ribbon alpha and
turquoise-ribbon beta icons, heroes and data-rich covers in the corresponding
subfolders. The original screenshots remain unlabeled.

## About phase0

phase0 is a clean, customizable watch face built to keep useful information
easy to read.

[https://dawikur.dev/phase0](dawikur.dev/phase0)

Choose the fields, widgets and colors that matter. phase0 adapts the layout to
the available space and hides rows that are not in use.

Put the time first, then choose the details that matter to you. Add activity
and health metrics, weather, battery information, sunrise and sunset, or status
icons. Pick your colors and decide which data appears in the available areas.

### Make the layout yours

- Choose colors for the background, text, accents and clock.
- Add metrics such as heart rate, steps, floors, stress, Body Battery, calories
  and recovery time.
- Show weather details such as temperature, rain chance, UV index and wind.
- Add battery, alarm, phone connection and notification indicators.
- Choose sunrise and sunset information, with sun or moon icons.

In the phone settings, Global controls the face palette. Clock and Gauges can
use their own colors or inherit the matching color from Global. Clock also
offers an Auto or Small size. Status, Gauges, Top Metrics and Bottom Metrics
each appear once. Numbered fields identify the slots in order,
so you can tell which indicator or metric you are changing. Select a slot by its
data; the following field sets a gauge's accent or a middle metric's width.
Metric width defaults to Auto, which uses the selected data's preferred width
(three digits unless that data specifies otherwise). For example, UV index uses
two digits, pressure four and steps five. You can also choose one to ten digits
explicitly.

### Designed to adapt

phase0 measures the available screen space and adjusts the layout to fit.
Depending on the device and selected fields, it can resize text, rearrange the
spacing or omit lines that do not fit. The rows closest to the clock keep
their position when middle or outer rows are hidden; the remaining visible
rows spread into the free space. Smaller screens can show a simpler face;
larger screens can fit more information.

The watch face is designed with efficient updates in mind. Some data depends
on your device, Garmin Connect, available sensors and permissions, and may
not be available on every watch.

### Readable At A Glance

The large segmented clock stays dominant while secondary metrics keep their
own lanes.

### Adaptive Color System

Accent, foreground and background combinations keep the face readable across
bright daytime use and low-distraction AoD viewing.

### Built For Small Screens

The layout adapts to each watch screen and the widgets you choose, keeping
icons, labels, values and gauges clear at a glance.
