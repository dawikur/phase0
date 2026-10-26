# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Connect IQ Store screenshot scenarios.

Each scenario selects a manifest device and overrides app setting properties.
Property identifiers are the IDs from the generated ``properties.xml`` files.
Values can use the project's setting enums so they stay tied to the available
options instead of relying on unexplained numeric literals.
"""

from pathlib import Path
from typing import Any, cast

from data.settings import Source, Widgets
from data.settings.colors import Colors
from data.settings.data import Options
from scripts.utils.store_screenshots import Scenario

_DATA = Source(Path(__file__).resolve().parent.parent / "source" / "data")
_DATA_ALL = _DATA.all
_DATA_WITH_ICON = _DATA.with_icon
_DATA_WITH_VALUE_MAX = _DATA.with_value_max
_WIDGETS = cast(Any, Widgets(_DATA))

SCENARIOS = (
    Scenario(
        name="data-rich",
        device="fr955",
        properties={},
        title="Information at a glance",
        description="See weather, activity metrics, gauges and device status around the clock.",
        alt=(
            "phase0 with an orange clock on black, weather above, activity metrics below "
            "and gauges beside the clock"
        ),
        time_display="24h",
        units_display="metric",
    ),
    Scenario(
        name="small-screen",
        device="fr255s",
        properties={
            "GlobalAccent": Colors.LIGHT_AZURE.value,
            "GlobalBackground": Colors.BLACK.value,
            "ClockForeground": Colors.LIGHT_AZURE.value,
            "ClockShade": Colors.BLACK.value,
            "TopOuterData": _WIDGETS.BATTERY_PERCENTAGE.value,
            "BottomOuterData": _WIDGETS.NONE.value,
        },
        title="Fits smaller screens",
        description=(
            "Keep weather and activity data visible on a smaller display, with battery "
            "percentage at the top."
        ),
        alt=(
            "phase0 on a small display with a blue clock on black, battery percentage at "
            "the top and activity metrics below"
        ),
        preview_size="small",
        time_display="24h",
        units_display="metric",
    ),
    Scenario(
        name="selected-metrics",
        device="fr265s",
        properties={
            "GlobalAccent": Colors.LIGHT_PINK.value,
            "GlobalForeground": Colors.LIGHT_CYAN.value,
            "GlobalBackground": Colors.BLACK.value,
            "ClockForeground": Colors.LIGHT_PINK.value,
            "ClockShade": Colors.BLACK.value,
            "StatusData0": Options.NONE.value,
            "StatusData1": Options.NONE.value,
            "StatusData2": Options.NONE.value,
            "GaugesData0": _DATA_WITH_VALUE_MAX.STRESS.value,
            "GaugesAccent0": Colors.LIGHT_PINK.value,
            "GaugesData1": _DATA_WITH_VALUE_MAX.NONE.value,
            "GaugesData2": _DATA_WITH_VALUE_MAX.NONE.value,
            "TopOuterData": _WIDGETS.DAWN_AND_DUSK_SUN.value,
            "TopMiddleData0": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData1": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData2": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData3": _DATA_WITH_ICON.NONE.value,
            "BottomMiddleData0": _DATA_ALL.ALTITUDE.value,
            "BottomMiddleData1": _DATA_ALL.RECOVERY_TIME.value,
            "BottomMiddleData2": _DATA_ALL.NONE.value,
            "BottomMiddleData3": _DATA_ALL.NONE.value,
            "BottomOuterData": _WIDGETS.BATTERY_DAYS_REMAINING.value,
        },
        title="Choose your metrics",
        description=(
            "Show stress, altitude and recovery time alongside sunrise, sunset and "
            "remaining battery days."
        ),
        alt=(
            "phase0 with a pink clock on black, cyan values, a stress gauge, altitude, "
            "recovery time and sunrise and sunset times"
        ),
        time_display="12h",
        units_display="metric",
    ),
    Scenario(
        name="essentials",
        device="fenix7x",
        properties={
            "GlobalAccent": Colors.LIGHT_YELLOW.value,
            "GlobalForeground": Colors.LIGHT_CYAN.value,
            "GlobalBackground": Colors.BLUE.value,
            "ClockForeground": Colors.WHITE.value,
            "ClockShade": Colors.BLUE.value,
            "StatusData0": Options.NONE.value,
            "StatusData1": Options.NONE.value,
            "StatusData2": Options.NONE.value,
            "GaugesData0": _DATA_WITH_VALUE_MAX.NONE.value,
            "GaugesData1": _DATA_WITH_VALUE_MAX.NONE.value,
            "GaugesData2": _DATA_WITH_VALUE_MAX.NONE.value,
            "TopOuterData": _WIDGETS.NONE.value,
            "TopMiddleData0": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData1": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData2": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData3": _DATA_WITH_ICON.NONE.value,
            "BottomMiddleData0": _DATA_ALL.NONE.value,
            "BottomMiddleData1": _DATA_ALL.NONE.value,
            "BottomMiddleData2": _DATA_ALL.NONE.value,
            "BottomMiddleData3": _DATA_ALL.NONE.value,
            "BottomOuterData": _WIDGETS.NONE.value,
        },
        title="Just the essentials",
        description=(
            "Leave the clock, date and weather visible while hiding optional metrics, "
            "gauges and status icons."
        ),
        alt=(
            "phase0 with a white clock on blue, cyan date and weather text, and no "
            "optional metrics or gauges"
        ),
        time_display="24h",
        units_display="metric",
    ),
    Scenario(
        name="custom-colors",
        device="fenix7x",
        properties={
            "GlobalAccent": Colors.MAGENTA.value,
            "GlobalForeground": Colors.BLACK.value,
            "GlobalShade": Colors.MAGENTA.value,
            "GlobalBackground": Colors.WHITE.value,
            "ClockForeground": Colors.BLACK.value,
            "ClockShade": Colors.MAGENTA.value,
            "GaugesAccent0": Colors.MAGENTA.value,
            "GaugesAccent1": Colors.MAGENTA.value,
            "GaugesAccent2": Colors.MAGENTA.value,
            "TopOuterData": _WIDGETS.BATTERY_ICON.value,
            "TopMiddleData0": _DATA_WITH_ICON.UV_INDEX.value,
            "TopMiddleData1": _DATA_WITH_ICON.RAIN.value,
            "BottomMiddleData0": _DATA_ALL.ACTIVE_MINUTES_PER_DAY.value,
            "BottomMiddleData1": _DATA_ALL.DISTANCE.value,
            "BottomMiddleData2": _DATA_ALL.METERS_CLIMBED.value,
            "BottomOuterData": _WIDGETS.DAWN_OR_DUSK_MOON.value,
        },
        title="Make it your own",
        description=(
            "Pair a white background and magenta accents with your choice of weather and "
            "activity data."
        ),
        alt=(
            "phase0 with a black clock and magenta accents on white, showing weather, "
            "active minutes, distance and meters climbed"
        ),
        time_display="24h",
        units_display="statute",
    ),
    Scenario(
        name="flexible-layout",
        device="fenix7x",
        properties={
            "GlobalAccent": Colors.BLACK.value,
            "GlobalForeground": Colors.BLACK.value,
            "GlobalShade": Colors.CHARCOAL.value,
            "GlobalBackground": Colors.GREEN.value,
            "ClockForeground": Colors.BLACK.value,
            "ClockShade": Colors.GREEN.value,
            "GaugesAccent0": Colors.BLACK.value,
            "GaugesAccent1": Colors.BLACK.value,
            "GaugesAccent2": Colors.BLACK.value,
            "TopOuterData": _WIDGETS.DAWN_AND_DUSK_SUN.value,
            "TopMiddleData0": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData1": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData2": _DATA_WITH_ICON.NONE.value,
            "BottomMiddleWidth1": 5,
            "BottomMiddleData2": _DATA_ALL.NONE.value,
            "BottomOuterData": _WIDGETS.BATTERY_PERCENTAGE.value,
        },
        title="Room for your data",
        description=(
            "Adjust metric widths to fit longer values alongside heart rate, sunrise and "
            "sunset times."
        ),
        alt=(
            "phase0 with dark digits on green, sunrise and sunset times above the clock, "
            "and heart rate and steps below"
        ),
        time_display="12h",
        units_display="statute",
    ),
    Scenario(
        name="aod-ready",
        device="fr265s",
        properties={
            "GlobalAccent": Colors.INDIGO.value,
            "GlobalForeground": Colors.BLACK.value,
            "GlobalShade": Colors.CHARCOAL.value,
            "GlobalBackground": Colors.SILVER.value,
            "ClockForeground": Colors.CHARCOAL.value,
            "ClockShade": Colors.SILVER.value,
            "GaugesData0": _DATA_WITH_VALUE_MAX.PRESSURE.value,
            "GaugesAccent0": Colors.RED.value,
            "GaugesData1": _DATA_WITH_VALUE_MAX.RELATIVE_HUMIDITY.value,
            "GaugesAccent1": Colors.BLUE.value,
            "GaugesData2": _DATA_WITH_VALUE_MAX.SOLAR_INTENSITY.value,
            "GaugesAccent2": Colors.MAGENTA.value,
            "TopOuterData": _WIDGETS.BATTERY_PERCENTAGE.value,
            "TopMiddleData0": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData1": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData2": _DATA_WITH_ICON.NONE.value,
            "BottomMiddleData0": _DATA_ALL.FLOORS_DESCENDED.value,
            "BottomMiddleData1": _DATA_ALL.CALORIES.value,
            "BottomOuterData": _WIDGETS.NONE.value,
        },
        title="AoD ready",
        description="Keep the time visible with a minimal always-on display on AMOLED.",
        alt="phase0 on AMOLED with a gray normal layout and a minimal always-on display",
        time_display="24h",
        units_display="statute",
    ),
)
