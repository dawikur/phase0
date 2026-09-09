# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import IntEnum
from pathlib import Path
from typing import Any

import pytest

from data.settings import (
    Array,
    Boolean,
    Data,
    Number,
    Select,
    Settings,
    Single,
    Token,
    Widgets,
)
from data.settings.settings import MemoryHigh, MemoryLow, MemoryMedium


class Options(IntEnum):
    FIRST = 1
    SECOND = 2


def test_token_exposes_derived_names_and_compares_by_name() -> None:
    token = Token("heart rate")

    assert token.id == "HeartRate"
    assert token.variable == "heart_rate"
    assert token.label == "SET_HEART_RATE"
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

    data = Data(tmp_path)

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
    data = Data(Path("source/data"))
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
