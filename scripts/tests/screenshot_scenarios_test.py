# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import xml.etree.ElementTree as ET
from pathlib import Path

from data.devices import DEVICES
from data.screenshots import (
    _DATA_ALL,
    _DATA_WITH_ICON,
    _DATA_WITH_VALUE_MAX,
    _WIDGETS,
    SCENARIOS,
)
from data.settings.colors import Colors
from data.settings.data import Options
from scripts.utils.manifest import supported_connect_iq_ids
from scripts.utils.resources_jungle import memory_class_for_limit
from scripts.utils.store_screenshots import validate_scenarios


def test_screenshot_scenario_metadata_and_display_preferences() -> None:
    supported = supported_connect_iq_ids(Path("manifest.xml.tmpl"))
    assert validate_scenarios(SCENARIOS, supported) == list(SCENARIOS)
    assert [scenario.name for scenario in SCENARIOS] == [
        "data-rich",
        "small-screen",
        "selected-metrics",
        "essentials",
        "custom-colors",
        "flexible-layout",
        "aod-ready",
    ]
    assert {
        scenario.name: (scenario.time_display, scenario.units_display)
        for scenario in SCENARIOS
    } == {
        "data-rich": ("24h", "metric"),
        "small-screen": ("24h", "metric"),
        "selected-metrics": ("12h", "metric"),
        "essentials": ("24h", "metric"),
        "custom-colors": ("24h", "statute"),
        "flexible-layout": ("12h", "statute"),
        "aod-ready": ("24h", "statute"),
    }
    assert all(
        scenario.title and scenario.description and scenario.alt
        for scenario in SCENARIOS
    )
    assert all(
        (Path("site/assets/screenshots") / f"{scenario.name}{suffix}.png").is_file()
        for scenario in SCENARIOS
        for suffix in ("", "-aod")
    )


def test_screenshot_overrides_match_device_settings_options() -> None:
    supported = set(supported_connect_iq_ids(Path("manifest.xml.tmpl")))
    devices = {device.connect_iq_id: device for device in DEVICES}

    for scenario in SCENARIOS:
        assert scenario.device in supported
        memory = memory_class_for_limit(devices[scenario.device].memory.watch_face)
        resources = Path(f"resources/memory/{memory}/generated")
        properties = {
            prop.get("id"): prop.get("type")
            for prop in ET.parse(resources / "properties.xml").getroot()
        }
        options = {}
        for setting in ET.parse(resources / "settings.xml").iter("setting"):
            key = setting.get("propertyKey", "").removeprefix("@Properties.")
            config = setting.find("settingConfig")
            if config is not None and config.get("type") == "list":
                options[key] = {
                    int(entry.get("value", "")) for entry in config.findall("listEntry")
                }

        for key, value in scenario.properties.items():
            assert key in properties, f"{scenario.name}: unknown property {key}"
            assert (
                properties[key] == "Number"
            ), f"{scenario.name}: unexpected type for {key}"
            assert value in options[key], f"{scenario.name}: invalid {key}={value}"


def test_compact_magenta_and_focused_scenario_widgets() -> None:
    compact = next(s for s in SCENARIOS if s.name == "small-screen")
    assert compact.preview_size == "small"
    assert compact.properties["TopOuterData"] == _WIDGETS.BATTERY_PERCENTAGE.value
    assert compact.properties["BottomOuterData"] == _WIDGETS.NONE.value

    magenta = next(s for s in SCENARIOS if s.name == "custom-colors")
    assert magenta.properties["GlobalBackground"] == Colors.WHITE.value
    assert magenta.properties["GlobalShade"] == Colors.MAGENTA.value
    assert magenta.properties["ClockShade"] == Colors.MAGENTA.value
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

    focused = next(s for s in SCENARIOS if s.name == "selected-metrics")
    assert focused.properties["GaugesData0"] == _DATA_WITH_VALUE_MAX.STRESS.value
    assert focused.properties["TopMiddleData0"] == _DATA_WITH_ICON.NONE.value
    assert focused.properties["BottomMiddleData0"] == _DATA_ALL.ALTITUDE.value
    assert focused.properties["BottomMiddleData1"] == _DATA_ALL.RECOVERY_TIME.value
    assert focused.properties["TopOuterData"] == _WIDGETS.DAWN_AND_DUSK_SUN.value
    assert (
        focused.properties["BottomOuterData"] == _WIDGETS.BATTERY_DAYS_REMAINING.value
    )


def test_minimal_flexible_and_aod_scenario_widgets() -> None:
    minimal = next(s for s in SCENARIOS if s.name == "essentials")
    assert minimal.properties["TopMiddleData0"] == Options.NONE.value
    assert minimal.properties["BottomMiddleData3"] == Options.NONE.value
    assert minimal.properties["BottomOuterData"] == minimal.properties["TopOuterData"]

    flexible = next(s for s in SCENARIOS if s.name == "flexible-layout")
    assert flexible.properties["TopMiddleData0"] == Options.NONE.value
    assert flexible.properties["TopMiddleData1"] == Options.NONE.value
    assert flexible.properties["TopMiddleData2"] == Options.NONE.value
    assert flexible.properties["BottomMiddleData2"] == Options.NONE.value
    assert flexible.properties["BottomMiddleWidth1"] == 5
    assert flexible.properties["GlobalBackground"] == flexible.properties["ClockShade"]
    assert flexible.properties["GlobalBackground"] == Colors.GREEN.value
    assert flexible.properties["GlobalForeground"] == Colors.BLACK.value
    assert flexible.properties["GlobalAccent"] == Colors.BLACK.value
    assert flexible.properties["GlobalShade"] == Colors.CHARCOAL.value
    assert flexible.properties["BottomOuterData"] == _WIDGETS.BATTERY_PERCENTAGE.value

    aod = next(s for s in SCENARIOS if s.name == "aod-ready")
    assert aod.properties["TopOuterData"] == _WIDGETS.BATTERY_PERCENTAGE.value
    assert aod.properties["TopMiddleData0"] == _DATA_WITH_ICON.NONE.value
    assert aod.properties["TopMiddleData1"] == _DATA_WITH_ICON.NONE.value
    assert aod.properties["TopMiddleData2"] == _DATA_WITH_ICON.NONE.value
    assert aod.properties["BottomOuterData"] == _WIDGETS.NONE.value
    assert aod.properties["BottomMiddleData0"] == _DATA_ALL.FLOORS_DESCENDED.value
    assert aod.properties["BottomMiddleData1"] == _DATA_ALL.CALORIES.value
