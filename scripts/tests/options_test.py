# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import auto
from pathlib import Path
from unittest.mock import patch

import pytest

from data.settings.colors import Colors
from data.settings.data import ColorOptions, Options, Widgets
from data.settings.options import StableOptions
from data.settings.source import Datum, Source


def test_option_ids_do_not_depend_on_order_or_new_members() -> None:
    class Reordered(StableOptions):
        NEW_OPTION = auto()
        ICON = auto()
        ALARM = auto()

    assert Reordered.ALARM.value == Options.ALARM.value
    assert Reordered.ICON.value == Options.ICON.value
    assert Options.AUTO.value == 1345308750
    assert Options.NONE.value == 1225125243
    assert all(0x40000000 <= option.value <= 0x7FFFFFFF for option in Reordered)


def test_option_algorithm_is_stable() -> None:
    assert Options.ALARM.value == 1137411181


def test_option_collisions_are_rejected() -> None:
    with patch("data.settings.options.crc32", return_value=123):
        with pytest.raises(ValueError, match="Option ID collision for SECOND"):
            StableOptions("Collision", ["FIRST", "SECOND"])


def test_widget_ids_do_not_depend_on_data_count() -> None:
    data = Source(Path("source/data"))
    widgets = Widgets(data)
    empty_widgets = Widgets([])
    assert widgets["BATTERY_ICON"].value == empty_widgets["BATTERY_ICON"].value
    assert widgets["BATTERY_ICON"].value == Options.BATTERY_ICON.value
    assert widgets["NONE"].value == Options.NONE.value


def test_widget_collisions_are_rejected() -> None:
    with pytest.raises(ValueError, match="Widget ID collision for BATTERY_ICON"):
        with patch(
            "data.settings.source.stable_id", return_value=Options.BATTERY_ICON.value
        ):
            Widgets([Datum("CONFLICT", False, False)])


def test_metric_ids_survive_new_metrics_and_filtering(tmp_path: Path) -> None:
    for name in ("steps", "battery"):
        tmp_path.joinpath(f"{name}.mc").write_text(
            f"class {name.capitalize()} extends Base {{\n"
            f"const LABEL_{name.upper()} = 1;\n"
            "function initialize() {\nself.icon = Fonts.ICON_NONE;\nself.value_max = 100;\n}\n}"
        )
    before = Source(tmp_path)
    original = {datum.name: datum.value for datum in before}
    tmp_path.joinpath("altitude.mc").write_text(
        "class Altitude extends Base { const LABEL_ALTITUDE = 1; }"
    )
    after = Source(tmp_path)
    assert before.STEPS == after.STEPS == 1991171812
    assert before.BATTERY == after.BATTERY == 1482787097
    for datum in after:
        assert after.all[datum.name].value == datum.value
    for name, value in original.items():
        assert after.with_icon[name].value == value
        assert after.with_value_max[name].value == value
    assert after.BATTERY != Options.BATTERY_PERCENTAGE.value
    with patch("data.settings.source.stable_id", return_value=123):
        with pytest.raises(ValueError, match="Metric ID collision"):
            Source(tmp_path)


def test_global_color_uses_shared_stable_option_id() -> None:
    assert ColorOptions.GLOBAL.value == Options.GLOBAL.value == 1492995077
    assert [option.value for option in ColorOptions if option.name != "GLOBAL"] == [
        color.value for color in Colors
    ]
