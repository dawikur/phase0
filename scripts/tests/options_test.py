# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import auto
from pathlib import Path
from unittest.mock import patch

import pytest

from data.settings.data import Options, Widgets
from data.settings.options import StableOptions
from data.settings.source import Datum, Source


def test_option_ids_do_not_depend_on_order_or_new_members() -> None:
    class Reordered(StableOptions):
        NEW_OPTION = auto()
        ICON = auto()
        ALARM = auto()

    assert Reordered.ALARM.value == Options.ALARM.value
    assert Reordered.ICON.value == Options.ICON.value
    assert Options.AUTO.value == -1
    assert Options.NONE.value == 0
    assert all(0x40000000 <= option.value <= 0x7FFFFFFF for option in Reordered)


def test_option_algorithm_is_stable() -> None:
    assert Options.ALARM.value == 1137411181


def test_option_collisions_are_rejected() -> None:
    with patch("data.settings.options.crc32", return_value=123):
        with pytest.raises(ValueError, match="Option ID collision for SECOND"):

            class Collision(StableOptions):
                FIRST = auto()
                SECOND = auto()


def test_widget_ids_do_not_depend_on_data_count() -> None:
    data = Source(Path("source/data"))
    widgets = Widgets(data)
    empty_widgets = Widgets([])
    assert widgets.BATTERY_ICON.value == empty_widgets.BATTERY_ICON.value
    assert widgets.BATTERY_ICON.value == Options.BATTERY_ICON.value
    assert widgets.NONE.value == 0


def test_widget_collisions_are_rejected() -> None:
    with pytest.raises(ValueError, match="Widget ID collision for BATTERY_ICON"):
        Widgets([Datum("CONFLICT", Options.BATTERY_ICON.value, False, False)])
