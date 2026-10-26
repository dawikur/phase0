# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import IntEnum
from pathlib import Path
from typing import Any
from unittest.mock import patch

import pytest

from data.settings import (
    Array,
    Boolean,
    Number,
    Select,
    Settings,
    Single,
    Source,
    Token,
    Widgets,
)
from data.settings.data import MemoryHigh, MemoryLow, MemoryMedium, MetricWidths
from data.settings.data import Options as SettingOptions
from data.settings.data import Sizes
from data.settings.source import Datum


class Options(IntEnum):
    FIRST = 1
    SECOND = 2


def test_token_exposes_derived_names_and_compares_by_name() -> None:
    token = Token("heart rate")

    assert token.id == "HeartRate"
    assert token.variable == "heart_rate"
    assert token.setting == "SETTING_HEART_RATE"
    assert token == Token("heart rate", "OtherClass")
    assert token != Token("steps")
    assert token != "heart rate"
    assert hash(token) == hash(Token("heart rate"))


def test_select_supports_an_explicit_option_enum() -> None:
    select = Select("size", Options.FIRST, option_type=Options)

    assert select.default == "1"
    assert [option.name for option in select] == ["FIRST", "SECOND"]


def test_array_rejects_inconsistent_rows() -> None:
    with pytest.raises(AssertionError, match="has length"):
        Array("items", "Item", [[Number("width", 1)], []])

    with pytest.raises(AssertionError, match="has type"):
        Array("items", "Item", [[Number("width", 1)], [Boolean("width", True)]])

    with pytest.raises(AssertionError, match="has name"):
        Array("items", "Item", [[Number("width", 1)], [Number("height", 1)]])

    array = Array("items", "Item", [[Number("width", 1)]])
    assert len(array) == 1
    assert array[0][0].default == 1

    single = Single("item", "Item", [Number("width", 1)])
    assert single[0].default == 1


def test_data_reads_metrics_and_filters_their_features(tmp_path: Path) -> None:
    (tmp_path / "ignored.mc").write_text("module Ignored {}", encoding="utf-8")
    (tmp_path / "steps.mc").write_text(
        "(:data_gauge,:data_icon)\n"
        "class Steps extends Base {\n"
        "const LABEL_STEPS = 1;\n"
        "function initialize() {\n"
        "self.icon = Fonts.ICON_STEPS;\n"
        "self.value_max = 100;\n"
        "}\n",
        encoding="utf-8",
    )
    (tmp_path / "battery.mc").write_text(
        "class Battery extends Base {\n" + "const LABEL_BATTERY = 1;\n" + "}",
        encoding="utf-8",
    )
    (tmp_path / "nested").mkdir()

    data = Source(tmp_path)
    assert len(data) == 2

    assert [(item.name, item.value) for item in data] == [
        ("BATTERY", 1482787097),
        ("STEPS", 1991171812),
    ]
    assert [item.name for item in data.all] == ["NONE", "BATTERY", "STEPS"]
    assert [item.name for item in data.with_icon] == ["NONE", "STEPS"]
    assert [item.name for item in data.with_value_max] == ["NONE", "STEPS"]
    assert data.STEPS == 1991171812
    with pytest.raises(AttributeError, match="UNKNOWN"):
        _ = data.UNKNOWN


def test_settings_builds_data_widget_values_from_data() -> None:
    data = Source(Path("source/data"))
    data_widget: Any = Widgets(data)

    assert data_widget.NONE == SettingOptions.NONE
    for name in ("BATTERY_DAYS_REMAINING", "BATTERY_ICON", "BATTERY_PERCENTAGE"):
        assert getattr(data_widget, name) == getattr(SettingOptions, name)
        assert getattr(data_widget, name) not in {datum.value for datum in data}
    assert MemoryLow(data, data_widget)
    assert MemoryMedium(data, data_widget)
    assert MemoryHigh(data, data_widget)


def test_settings_supports_indexed_and_named_access() -> None:
    clock = Single("clock", "Clock", [])
    settings = Settings(clock)

    assert settings[0] is clock
    assert settings["clock"] is clock
    assert settings.get("clock") is clock
    assert settings.get("missing") is None
    assert list(settings) == [clock]
    assert len(settings) == 1


def test_auto_options_share_stable_ids_and_preserve_other_option_ids() -> None:
    assert SettingOptions.AUTO == Sizes.AUTO == MetricWidths.AUTO == 1345308750
    assert MetricWidths.NONE == SettingOptions.NONE == 1225125243
    assert [
        width.value for width in MetricWidths if width.name.startswith("WIDTH_")
    ] == list(range(1, 11))
    assert [
        (option.name, option.value)
        for option in SettingOptions
        if option.name != "AUTO"
    ] == [
        ("NONE", 1225125243),
        ("GLOBAL", 1492995077),
        ("ALARM", 1137411181),
        ("BATTERY_DAYS_REMAINING", 2133686479),
        ("BATTERY_ICON", 1505374502),
        ("BATTERY_PERCENTAGE", 1198069765),
        ("BLUETOOTH_CONNECTED", 1174323477),
        ("BLUETOOTH_DISCONNECTED", 1258132274),
        ("DAWN_AND_DUSK", 1955290810),
        ("DAWN_AND_DUSK_MOON", 1607138032),
        ("DAWN_AND_DUSK_SUN", 1368050790),
        ("DAWN_OR_DUSK", 1496803785),
        ("DAWN_OR_DUSK_MOON", 1537828135),
        ("DAWN_OR_DUSK_SUN", 1764953824),
        ("GAUGE", 1554042010),
        ("ICON", 1392624751),
        ("NOTIFICATIONS", 1179431478),
        ("SMALL", 1108420771),
    ]


def test_relative_humidity_is_available_for_icons_and_gauges() -> None:
    data = Source(Path("source/data"))
    assert data.with_icon.RELATIVE_HUMIDITY == data.RELATIVE_HUMIDITY
    assert data.with_value_max.RELATIVE_HUMIDITY == data.RELATIVE_HUMIDITY


def test_move_bar_is_available_for_icons_and_gauges() -> None:
    data = Source(Path("source/data"))
    assert data.with_icon.MOVE_BAR == data.MOVE_BAR
    assert data.with_value_max.MOVE_BAR == data.MOVE_BAR


@pytest.mark.parametrize("metric", ["BATTERY_PERCENTAGE", "BODY_BATTERY"])
def test_battery_metrics_are_available_for_icons_and_gauges(metric: str) -> None:
    data = Source(Path("source/data"))
    assert getattr(data.with_icon, metric) == getattr(data, metric)
    assert getattr(data.with_value_max, metric) == getattr(data, metric)


def test_battery_days_remaining_is_available_for_icons() -> None:
    data = Source(Path("source/data"))
    assert data.with_icon.BATTERY_DAYS_REMAINING == data.BATTERY_DAYS_REMAINING


def test_solar_intensity_is_available_for_icons_and_gauges() -> None:
    data = Source(Path("source/data"))
    assert data.with_icon.SOLAR_INTENSITY == data.SOLAR_INTENSITY
    assert data.with_value_max.SOLAR_INTENSITY == data.SOLAR_INTENSITY


def test_widget_ids_reject_collision_with_metric_ids() -> None:
    with patch(
        "data.settings.source.stable_id", return_value=SettingOptions.BATTERY_ICON.value
    ):
        datum = Datum("COLLIDING_METRIC", False, False)
    with pytest.raises(ValueError, match="Widget ID collision for BATTERY_ICON"):
        Widgets([datum])


@pytest.mark.parametrize("has_icon", [False, True])
@pytest.mark.parametrize("has_gauge", [False, True])
@pytest.mark.parametrize("is_status", [False, True])
def test_capabilities_use_annotations(
    tmp_path: Path, has_icon: bool, has_gauge: bool, is_status: bool
) -> None:
    markers = ",".join(
        f":{name}"
        for name, enabled in (
            ("data_gauge", has_gauge),
            ("data_icon", has_icon),
            ("data_status", is_status),
        )
        if enabled
    )
    annotations = f"({markers})" if markers else ""
    metric = tmp_path / "sample.mc"
    metric.write_text(
        annotations + "\nclass Sample extends Base { const LABEL_SAMPLE = 1; }"
    )
    data = Source(tmp_path)
    datum = next(iter(data))
    assert datum.has_icon == has_icon
    assert datum.has_value_max == has_gauge
    assert datum.is_status == is_status
    assert ("SAMPLE" in data.with_icon.__members__) == has_icon
    assert ("SAMPLE" in data.with_value_max.__members__) == has_gauge
    assert ("SAMPLE" in data.status.__members__) == is_status
    metric.write_text(
        annotations + "\nclass Sample extends Base {\n"
        "const LABEL_SAMPLE = 1;\nfunction initialize() {\n"
        "self.icon = Fonts.ICON_EMPTY;\nself.value_max = 100;\n}\n}"
    )
    assert list(Source(tmp_path)) == [datum]
