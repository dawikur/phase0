# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from enum import IntEnum, auto
from typing import Any, cast

from .colors import Colors
from .data import Data
from .model import Array, Number, Select, Single


class Options(IntEnum):
    DISABLED = auto()

    ALARM = auto()
    AUTO = auto()
    BATTERY_DAYS_REMAINING = auto()
    BATTERY_ICON = auto()
    BATTERY_PERCENTAGE = auto()
    BLUETOOTH_CONNECTED = auto()
    BLUETOOTH_DISCONNECTED = auto()
    DAWN_DUSK_MOON = auto()
    DAWN_OR_DUSK_MOON = auto()
    GAUGE = auto()
    ICON = auto()
    LARGE = auto()
    NOTIFICATIONS = auto()
    SMALL = auto()


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

    BATTERY_DAYS_REMAINING = Options.BATTERY_DAYS_REMAINING.value
    BATTERY_ICON = Options.BATTERY_ICON.value
    BATTERY_PERCENTAGE = Options.BATTERY_PERCENTAGE.value
    DAWN_DUSK_MOON = Options.DAWN_DUSK_MOON.value
    DAWN_OR_DUSK_MOON = Options.DAWN_OR_DUSK_MOON.value


class MetricStyle(IntEnum):
    DISABLED = Options.DISABLED.value

    ICON = Options.ICON.value
    GAUGE = Options.GAUGE.value


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
            "Gauge",
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
                Select("data", DataWidget.DAWN_DUSK_MOON),
            ],
        ),
        Array(
            "top middle",
            "Metric",
            [
                [
                    Select("data", DataWithIcon.RAIN),
                    Number("width", 2),
                ],
                [
                    Select("data", DataWithIcon.UV_INDEX),
                    Number("width", 2),
                ],
                [
                    Select("data", DataWithIcon.WIND_BEARING),
                    Number("width", 2),
                ],
                [
                    Select("data", DataWithIcon.DISABLED),
                    Number("width", 2),
                ],
            ],
        ),
        # Array(
        #    "top middle alt",
        #    "Metric",
        #    [
        #        [
        #            Select("data", DataWithIcon.DISABLED),
        #            Number("width", 2),
        #        ],
        #        [
        #            Select("data", DataWithIcon.DISABLED),
        #            Number("width", 2),
        #        ],
        #        [
        #            Select("data", DataWithIcon.DISABLED),
        #            Number("width", 2),
        #        ],
        #        [
        #            Select("data", DataWithIcon.DISABLED),
        #            Number("width", 2),
        #        ],
        #    ],
        # ),
        Array(
            "bottom middle",
            "Metric",
            [
                [
                    Select("data", DataAll.HEART_RATE),
                    Number("width", 3),
                ],
                [
                    Select("data", DataAll.STEPS),
                    Number("width", 3),
                ],
                [
                    Select("data", DataAll.FLOORS_CLIMBED),
                    Number("width", 3),
                ],
                [
                    Select("data", DataAll.DISABLED),
                    Number("width", 3),
                ],
            ],
        ),
        # Array(
        #    "bottom middle alt",
        #    "Metric",
        #    [
        #        [
        #            Select("data", DataAll.CALORIES),
        #            Number("width", 5),
        #        ],
        #        [
        #            Select("data", DataAll.SOLAR_INTENSITY),
        #            Number("width", 3),
        #        ],
        #        [
        #            Select("data", DataAll.DISABLED),
        #            Number("width", 3),
        #        ],
        #        [
        #            Select("data", DataAll.DISABLED),
        #            Number("width", 3),
        #        ],
        #    ],
        # ),
        Single(
            "bottom outer",
            "Widget",
            [
                Select("data", DataWidget.BATTERY_ICON),
            ],
        ),
    ]
