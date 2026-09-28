# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Connect IQ Store screenshot scenarios.

Each scenario selects a manifest device and overrides app setting properties.
Property identifiers are the IDs from the generated ``properties.xml`` files.
Values can use the project's setting enums so they stay tied to the available
options instead of relying on unexplained numeric literals.
"""

from pathlib import Path
from typing import Any, cast

from data.settings import Data, Widgets
from data.settings.colors import Colors
from data.settings.settings import Status
from scripts.utils.store_screenshots import Scenario

_DATA = Data(Path(__file__).resolve().parent.parent / "source" / "data")
_DATA_ALL = _DATA.all
_DATA_WITH_ICON = _DATA.with_icon
_DATA_WITH_VALUE_MAX = _DATA.with_value_max
_WIDGETS = cast(Any, Widgets(_DATA))

SCENARIOS = (
    Scenario(
        name="data-rich",
        device="fenix7x",
        properties={},
        title="Information at a glance",
        description="Metrics, weather, status and battery in one dense layout.",
        alt="Data-rich phase0 layout with the clock, status icons, gauges, metrics and weather",
    ),
    Scenario(
        name="compact",
        device="fr255s",
        properties={
            "GeneralAccent": Colors.LIGHT_AZURE.value,
            "GeneralBackground": Colors.BLACK.value,
            "ClockForeground": Colors.LIGHT_AZURE.value,
            "ClockBackground": Colors.BLACK.value,
            "TopOuterData": _WIDGETS.BATTERY_PERCENTAGE.value,
            "BottomOuterData": _WIDGETS.NONE.value,
        },
        title="Adapts to smaller screens",
        description="Compact spacing and a relocated battery percentage.",
        alt="Compact phase0 layout with blue accents and battery percentage",
        preview_size="small",
    ),
    Scenario(
        name="indigo-accent",
        device="fenix7x",
        properties={
            "GeneralAccent": Colors.LIGHT_INDIGO.value,
            "GeneralBackground": Colors.BLACK.value,
            "ClockForeground": Colors.WHITE.value,
            "ClockBackground": Colors.BLACK.value,
            "GaugesAccent0": Colors.LIGHT_INDIGO.value,
            "GaugesAccent1": Colors.LIGHT_INDIGO.value,
            "GaugesAccent2": Colors.LIGHT_INDIGO.value,
            "TopOuterData": _WIDGETS.BATTERY_PERCENTAGE.value,
            "BottomOuterData": _WIDGETS.NONE.value,
        },
        title="Accents",
        description="Change the global accent, gauges and widget placement.",
        alt="phase0 color scheme with battery percentage at the top",
    ),
    Scenario(
        name="reduced",
        device="fenix7x",
        properties={
            "GeneralAccent": Colors.LIGHT_PINK.value,
            "GeneralForeground": Colors.LIGHT_CYAN.value,
            "GeneralBackground": Colors.BLACK.value,
            "ClockForeground": Colors.LIGHT_PINK.value,
            "ClockBackground": Colors.BLACK.value,
            "StatusData0": Status.NONE.value,
            "StatusData1": Status.NONE.value,
            "StatusData2": Status.NONE.value,
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
        title="A focused data set",
        description="Choose a few useful metrics and leave the other rows clear.",
        alt="phase0 layout with a stress gauge, altitude, recovery time, sunrise and sunset",
    ),
    Scenario(
        name="empty-layout",
        device="fenix7x",
        properties={
            "GeneralAccent": Colors.LIGHT_YELLOW.value,
            "GeneralForeground": Colors.LIGHT_CYAN.value,
            "GeneralBackground": Colors.BLUE.value,
            "ClockForeground": Colors.WHITE.value,
            "ClockBackground": Colors.BLUE.value,
            "StatusData0": Status.NONE.value,
            "StatusData1": Status.NONE.value,
            "StatusData2": Status.NONE.value,
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
        title="Minimal layout",
        description="Remove optional fields for a clean, open face.",
        alt="Minimal phase0 layout with a blue background, cyan text and a white clock",
    ),
    Scenario(
        name="magenta-accent",
        device="fenix7x",
        properties={
            "GeneralAccent": Colors.MAGENTA.value,
            "GeneralForeground": Colors.BLACK.value,
            "GeneralShade": Colors.MAGENTA.value,
            "GeneralBackground": Colors.WHITE.value,
            "ClockForeground": Colors.BLACK.value,
            "ClockBackground": Colors.MAGENTA.value,
            "GaugesAccent0": Colors.MAGENTA.value,
            "GaugesAccent1": Colors.MAGENTA.value,
            "GaugesAccent2": Colors.MAGENTA.value,
            "TopMiddleData0": _DATA_WITH_ICON.UV_INDEX.value,
            "TopMiddleData1": _DATA_WITH_ICON.RAIN.value,
            "BottomMiddleData0": _DATA_ALL.ACTIVE_MINUTES_PER_DAY.value,
            "BottomMiddleData1": _DATA_ALL.DISTANCE.value,
            "BottomMiddleData2": _DATA_ALL.METERS_CLIMBED.value,
        },
        title="Make color your own",
        description="Rearrange the data and adjust the palette for a distinct look.",
        alt="phase0 layout with active minutes, distance and elevation data in a magenta palette",
    ),
    Scenario(
        name="sunrise",
        device="fenix7x",
        properties={
            "GeneralAccent": Colors.RED.value,
            "GeneralForeground": Colors.BLACK.value,
            "GeneralShade": Colors.ORANGE.value,
            "GeneralBackground": Colors.LIGHT_YELLOW.value,
            "ClockForeground": Colors.RED.value,
            "ClockBackground": Colors.LIGHT_YELLOW.value,
            "GaugesAccent0": Colors.BLUE.value,
            "GaugesAccent1": Colors.INDIGO.value,
            "GaugesAccent2": Colors.MAGENTA.value,
            "TopOuterData": _WIDGETS.DAWN_AND_DUSK_SUN.value,
            "TopMiddleData0": _DATA_WITH_ICON.NONE.value,
            "TopMiddleData1": _DATA_WITH_ICON.WIND.value,
            "TopMiddleData2": _DATA_WITH_ICON.UV_INDEX.value,
            "BottomMiddleWidth1": 5,
            "BottomMiddleData2": _DATA_ALL.NONE.value,
            "BottomOuterData": _WIDGETS.BATTERY_PERCENTAGE.value,
        },
        title="Choose your data",
        description="Choose which information to show and let the layout adapt.",
        alt="phase0 sunrise and sunset widget with a five-character steps value",
    ),
    Scenario(
        name="gray-mix",
        device="fenix7x",
        properties={
            "GeneralAccent": Colors.INDIGO.value,
            "GeneralForeground": Colors.BLACK.value,
            "GeneralShade": Colors.CHARCOAL.value,
            "GeneralBackground": Colors.SILVER.value,
            "ClockForeground": Colors.BLACK.value,
            "ClockBackground": Colors.SILVER.value,
            "GaugesData0": _DATA_WITH_VALUE_MAX.PRESSURE.value,
            "GaugesAccent0": Colors.RED.value,
            "GaugesData1": _DATA_WITH_VALUE_MAX.RELATIVE_HUMIDITY.value,
            "GaugesAccent1": Colors.BLUE.value,
            "GaugesData2": _DATA_WITH_VALUE_MAX.SOLAR_INTENSITY.value,
            "GaugesAccent2": Colors.MAGENTA.value,
            "TopMiddleData0": _DATA_WITH_ICON.WIND.value,
            "TopMiddleData1": _DATA_WITH_ICON.RAIN.value,
            "TopMiddleData2": _DATA_WITH_ICON.UV_INDEX.value,
            "BottomMiddleData0": _DATA_ALL.FLOORS_DESCENDED.value,
            "BottomMiddleData1": _DATA_ALL.CALORIES.value,
            "BottomOuterData": _WIDGETS.BATTERY_PERCENTAGE.value,
        },
        title="A different combination",
        description="Pair a neutral background with a fresh arrangement of data.",
        alt="phase0 layout with a gray background, weather and activity data",
    ),
)
