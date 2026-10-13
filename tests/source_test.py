# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import IntEnum
from pathlib import Path
from typing import Any

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

    assert [(item.name, item.value) for item in data] == [
        ("BATTERY", 1),
        ("STEPS", 2),
    ]
    assert [item.name for item in data.all] == ["NONE", "BATTERY", "STEPS"]
    assert [item.name for item in data.with_icon] == ["NONE", "STEPS"]
    assert [item.name for item in data.with_value_max] == ["NONE", "STEPS"]
    assert data.STEPS == 2
    with pytest.raises(AttributeError, match="UNKNOWN"):
        _ = data.UNKNOWN


def test_settings_builds_data_widget_values_from_data() -> None:
    data = Source(Path("source/data"))
    data_widget: Any = Widgets(data)

    assert data_widget.NONE == len(data) + 1
    assert data_widget.BATTERY_DAYS_REMAINING > data_widget.NONE
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


def test_auto_options_share_minus_one_and_preserve_other_option_ids() -> None:
    assert SettingOptions.AUTO == Sizes.AUTO == MetricWidths.AUTO == -1
    assert [
        (option.name, option.value)
        for option in SettingOptions
        if option.name != "AUTO"
    ] == [
        ("NONE", 1),
        ("ALARM", 2),
        ("BATTERY_DAYS_REMAINING", 4),
        ("BATTERY_ICON", 5),
        ("BATTERY_PERCENTAGE", 6),
        ("BLUETOOTH_CONNECTED", 7),
        ("BLUETOOTH_DISCONNECTED", 8),
        ("DAWN_AND_DUSK", 9),
        ("DAWN_AND_DUSK_MOON", 10),
        ("DAWN_AND_DUSK_SUN", 11),
        ("DAWN_OR_DUSK", 12),
        ("DAWN_OR_DUSK_MOON", 13),
        ("DAWN_OR_DUSK_SUN", 14),
        ("GAUGE", 15),
        ("ICON", 16),
        ("NOTIFICATIONS", 17),
        ("SMALL", 18),
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
