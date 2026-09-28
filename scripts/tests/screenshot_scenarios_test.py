# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from data.screenshots import (
    _DATA_ALL,
    _DATA_WITH_ICON,
    _DATA_WITH_VALUE_MAX,
    _WIDGETS,
    SCENARIOS,
)
from data.settings.colors import Colors


def test_screenshot_scenario_metadata_and_display_preferences() -> None:
    assert [scenario.name for scenario in SCENARIOS] == [
        "data-rich",
        "compact",
        "focused-metrics",
        "minimal-layout",
        "magenta-accent",
        "retro-lcd",
        "weather-gauges",
    ]
    assert {
        scenario.name: (scenario.time_display, scenario.units_display)
        for scenario in SCENARIOS
    } == {
        "data-rich": ("24h", "metric"),
        "compact": ("24h", "metric"),
        "focused-metrics": ("12h", "metric"),
        "minimal-layout": ("24h", "metric"),
        "magenta-accent": ("24h", "statute"),
        "retro-lcd": ("12h", "statute"),
        "weather-gauges": ("24h", "statute"),
    }
    assert all(
        scenario.title and scenario.description and scenario.alt
        for scenario in SCENARIOS
    )


def test_compact_magenta_and_focused_scenario_widgets() -> None:
    compact = next(s for s in SCENARIOS if s.name == "compact")
    assert compact.preview_size == "small"
    assert compact.properties["TopOuterData"] == _WIDGETS.BATTERY_PERCENTAGE.value
    assert compact.properties["BottomOuterData"] == _WIDGETS.NONE.value

    magenta = next(s for s in SCENARIOS if s.name == "magenta-accent")
    assert magenta.properties["GeneralBackground"] == Colors.WHITE.value
    assert magenta.properties["GeneralShade"] == Colors.MAGENTA.value
    assert magenta.properties["ClockBackground"] == Colors.MAGENTA.value
    assert magenta.properties["ClockForeground"] == Colors.BLACK.value
    assert magenta.properties["TopMiddleData0"] == _DATA_WITH_ICON.UV_INDEX.value
    assert magenta.properties["TopMiddleData1"] == _DATA_WITH_ICON.RAIN.value
    assert magenta.properties["TopOuterData"] == _WIDGETS.BATTERY_ICON.value
    assert magenta.properties["BottomOuterData"] == _WIDGETS.DAWN_OR_DUSK_MOON.value
    assert (
        magenta.properties["BottomMiddleData0"]
        == _DATA_ALL.ACTIVE_MINUTES_PER_DAY.value
    )
    assert magenta.properties["BottomMiddleData1"] == _DATA_ALL.DISTANCE.value
    assert magenta.properties["BottomMiddleData2"] == _DATA_ALL.METERS_CLIMBED.value

    focused = next(s for s in SCENARIOS if s.name == "focused-metrics")
    assert focused.properties["GaugesData0"] == _DATA_WITH_VALUE_MAX.STRESS.value
    assert focused.properties["TopMiddleData0"] == _DATA_WITH_ICON.NONE.value
    assert focused.properties["BottomMiddleData0"] == _DATA_ALL.ALTITUDE.value
    assert focused.properties["BottomMiddleData1"] == _DATA_ALL.RECOVERY_TIME.value
    assert focused.properties["TopOuterData"] == _WIDGETS.DAWN_AND_DUSK_SUN.value
    assert (
        focused.properties["BottomOuterData"] == _WIDGETS.BATTERY_DAYS_REMAINING.value
    )


def test_minimal_retro_and_weather_scenario_widgets() -> None:
    minimal = next(s for s in SCENARIOS if s.name == "minimal-layout")
    assert minimal.properties["TopMiddleData0"] == 0
    assert minimal.properties["BottomMiddleData3"] == 0
    assert minimal.properties["BottomOuterData"] == minimal.properties["TopOuterData"]

    retro = next(s for s in SCENARIOS if s.name == "retro-lcd")
    assert retro.properties["TopMiddleData0"] == 0
    assert retro.properties["TopMiddleData1"] == 0
    assert retro.properties["TopMiddleData2"] == 0
    assert retro.properties["BottomMiddleData2"] == 0
    assert retro.properties["BottomMiddleWidth1"] == 5
    assert retro.properties["GeneralBackground"] == retro.properties["ClockBackground"]
    assert retro.properties["GeneralBackground"] == Colors.GREEN.value
    assert retro.properties["GeneralForeground"] == Colors.BLACK.value
    assert retro.properties["GeneralAccent"] == Colors.BLACK.value
    assert retro.properties["GeneralShade"] == Colors.CHARCOAL.value
    assert retro.properties["BottomOuterData"] == _WIDGETS.BATTERY_PERCENTAGE.value

    weather = next(s for s in SCENARIOS if s.name == "weather-gauges")
    assert weather.properties["TopOuterData"] == _WIDGETS.BATTERY_PERCENTAGE.value
    assert weather.properties["TopMiddleData0"] == _DATA_WITH_ICON.NONE.value
    assert weather.properties["TopMiddleData1"] == _DATA_WITH_ICON.NONE.value
    assert weather.properties["TopMiddleData2"] == _DATA_WITH_ICON.NONE.value
    assert weather.properties["BottomOuterData"] == _WIDGETS.NONE.value
    assert weather.properties["BottomMiddleData0"] == _DATA_ALL.FLOORS_DESCENDED.value
    assert weather.properties["BottomMiddleData1"] == _DATA_ALL.CALORIES.value
