# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from enum import IntEnum, auto
from typing import Any, cast

from .colors import Colors
from .data import Data
from .model import Array, Boolean, Number, Select, Single


class Options(IntEnum):
    DISABLED = auto()

    ALARM = auto()
    AUTO = auto()
    BLUETOOTH_CONNECTED = auto()
    BLUETOOTH_DISCONNECTED = auto()
    BATTERY_DAYS_REMAINING = auto()
    BATTERY_ICON = auto()
    LARGE = auto()
    NOTIFICATIONS = auto()
    BATTERY_PERCENTAGE = auto()
    SMALL = auto()
    SUN_MOON = auto()
    # Reserved for future widget types.
    # AM_PM = auto()
    # DATE = auto()
    # SECONDS = auto()
    # WEATHER = auto()


class Heights(IntEnum):
    AUTO = Options.AUTO.value
    LARGE = Options.LARGE.value
    SMALL = Options.SMALL.value


class Status(IntEnum):
    DISABLED = Options.DISABLED.value

    ALARM = Options.ALARM.value
    BLUETOOTH_CONNECTED = Options.BLUETOOTH_CONNECTED.value
    BLUETOOTH_DISCONNECTED = Options.BLUETOOTH_DISCONNECTED.value
    NOTIFICATIONS = Options.NOTIFICATIONS.value


class DataExtra(IntEnum):
    DISABLED = Options.DISABLED.value

    # AM_PM = Options.AM_PM.value
    BATTERY_DAYS_REMAINING = Options.BATTERY_DAYS_REMAINING.value
    BATTERY_ICON = Options.BATTERY_ICON.value
    BATTERY_PERCENTAGE = Options.BATTERY_PERCENTAGE.value
    # DATE = Options.DATE.value
    # SECONDS = Options.SECONDS.value
    SUN_MOON = Options.SUN_MOON.value
    # WEATHER = Options.WEATHER.value


def Settings(  # pylint: disable=invalid-name
    data: Data,
) -> tuple[IntEnum, list[Single | Array]]:
    DataWidget = cast(
        Any,
        IntEnum(
            "DataWidget", {datum.name: datum.value + len(data) for datum in DataExtra}
        ),
    )

    DataAll = data.all
    DataWithIcon = data.with_icon
    DataWithValueMax = data.with_value_max

    return DataWidget, [
        Single(
            "general",
            "General",
            [
                Select("accent", Colors.ORANGE),
                Select("foreground", Colors.WHITE),
                Select("shade", Colors.CHARCOAL),
                Select("background", Colors.BLACK),
            ],
        ),
        Single(
            "clock",
            "Clock",
            [
                Select("foreground", Colors.LIGHT_ORANGE),
                Select("background", Colors.CHARCOAL),
                Select("height", Heights.AUTO),
            ],
        ),
        Array(
            "status",
            "Status",
            [
                [
                    Select("data", Status.ALARM),
                ],
                [
                    Select("data", Status.BLUETOOTH_CONNECTED),
                ],
                [
                    Select("data", Status.NOTIFICATIONS),
                ],
                [
                    Select("data", Status.DISABLED),
                ],
            ],
        ),
        Array(
            "gauges",
            "Widget",
            [
                [
                    Select("data", DataWithValueMax.BODY_BATTERY),
                    Select("accent", Colors.CYAN),
                ],
                [
                    Select("data", DataWithValueMax.STRESS),
                    Select("accent", Colors.YELLOW),
                ],
                [
                    Select("data", DataWithValueMax.MOVE_BAR),
                    Select("accent", Colors.RED),
                ],
                [
                    Select("data", DataWithValueMax.DISABLED),
                    Select("accent", Colors.MAGENTA),
                ],
            ],
        ),
        Single(
            "top outer",
            "Widget",
            [
                Select("data", DataWidget.SUN_MOON),
                Select("accent", Colors.ORANGE),
            ],
        ),
        Array(
            "top middle",
            "Metric",
            [
                [
                    Select("data", DataWithIcon.RAIN),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
                [
                    Select("data", DataWithIcon.UV_INDEX),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
                [
                    Select("data", DataWithIcon.WIND_BEARING),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
                [
                    Select("data", DataWithIcon.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
            ],
        ),
        Array(
            "top middle alt",
            "Metric",
            [
                [
                    Select("data", DataWithIcon.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
                [
                    Select("data", DataWithIcon.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
                [
                    Select("data", DataWithIcon.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
                [
                    Select("data", DataWithIcon.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 2),
                    Boolean("icon", True, hidden=True),
                    Boolean("padding", False, hidden=True),
                    Boolean("gauge", False, hidden=True),
                ],
            ],
        ),
        Array(
            "bottom middle",
            "Metric",
            [
                [
                    Select("data", DataAll.HEART_RATE),
                    Select("accent", Colors.ORANGE),
                    Number("width", 3),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
                [
                    Select("data", DataAll.STEPS),
                    Select("accent", Colors.ORANGE),
                    Number("width", 3),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
                [
                    Select("data", DataAll.FLOORS_CLIMBED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 3),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
                [
                    Select("data", DataAll.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 3),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
            ],
        ),
        Array(
            "bottom middle alt",
            "Metric",
            [
                [
                    Select("data", DataAll.CALORIES),
                    Select("accent", Colors.ORANGE),
                    Number("width", 5),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
                [
                    Select("data", DataAll.SOLAR_INTENSITY),
                    Select("accent", Colors.ORANGE),
                    Number("width", 3),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
                [
                    Select("data", DataAll.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 3),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
                [
                    Select("data", DataAll.DISABLED),
                    Select("accent", Colors.ORANGE),
                    Number("width", 3),
                    Boolean("icon", False, hidden=True),
                    Boolean("padding", True, hidden=True),
                    Boolean("gauge", True, hidden=True),
                ],
            ],
        ),
        Single(
            "bottom outer",
            "Widget",
            [
                Select("data", DataWidget.BATTERY_ICON),
                Select("accent", Colors.ORANGE),
            ],
        ),
    ]
