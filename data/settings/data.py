# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import IntEnum, auto
from typing import Any, cast

from .colors import Colors
from .model import Array, Select, Settings, Single
from .source import Source


class Options(IntEnum):
    NONE = auto()

    ALARM = auto()
    AUTO = -1
    # Preserve persisted option IDs after changing Auto from 3 to -1.
    BATTERY_DAYS_REMAINING = 4
    BATTERY_ICON = auto()
    BATTERY_PERCENTAGE = auto()
    BLUETOOTH_CONNECTED = auto()
    BLUETOOTH_DISCONNECTED = auto()
    DAWN_AND_DUSK = auto()
    DAWN_AND_DUSK_MOON = auto()
    DAWN_AND_DUSK_SUN = auto()
    DAWN_OR_DUSK = auto()
    DAWN_OR_DUSK_MOON = auto()
    DAWN_OR_DUSK_SUN = auto()
    GAUGE = auto()
    ICON = auto()
    NOTIFICATIONS = auto()
    SMALL = auto()


EXTRA_WIDGETS = [
    Options.NONE,
    Options.BATTERY_DAYS_REMAINING,
    Options.BATTERY_ICON,
    Options.BATTERY_PERCENTAGE,
    Options.DAWN_AND_DUSK,
    Options.DAWN_AND_DUSK_MOON,
    Options.DAWN_AND_DUSK_SUN,
    Options.DAWN_OR_DUSK,
    Options.DAWN_OR_DUSK_MOON,
    Options.DAWN_OR_DUSK_SUN,
]


class Sizes(IntEnum):
    AUTO = Options.AUTO.value
    SMALL = Options.SMALL.value


class MetricWidths(IntEnum):
    AUTO = Options.AUTO.value
    NONE = 0
    WIDTH_1 = 1
    WIDTH_2 = 2
    WIDTH_3 = 3
    WIDTH_4 = 4
    WIDTH_5 = 5
    WIDTH_6 = 6
    WIDTH_7 = 7
    WIDTH_8 = 8
    WIDTH_9 = 9
    WIDTH_10 = 10


ColorOptions = cast(
    Any,
    IntEnum(
        "ColorOptions",
        {"GLOBAL": -1, **{color.name: color.value for color in Colors}},
    ),
)


class Status(IntEnum):
    NONE = Options.NONE.value

    ALARM = Options.ALARM.value
    BLUETOOTH_CONNECTED = Options.BLUETOOTH_CONNECTED.value
    BLUETOOTH_DISCONNECTED = Options.BLUETOOTH_DISCONNECTED.value
    NOTIFICATIONS = Options.NOTIFICATIONS.value


class MetricStyle(IntEnum):
    NONE = Options.NONE.value

    ICON = Options.ICON.value
    GAUGE = Options.GAUGE.value


def Widgets(  # pylint: disable=invalid-name
    data: Source,
) -> type[IntEnum]:
    DataWidget = cast(
        Any,
        IntEnum(
            "Widget",
            {datum.name: datum.value + len(data) for datum in EXTRA_WIDGETS},
        ),
    )

    return DataWidget


def MemoryLow(  # pylint: disable=invalid-name
    data: Source,
    widgets: Any,
) -> Settings:
    DataAll = data.all
    DataWithIcon = data.with_icon
    DataWithValueMax = data.with_value_max

    return Settings(
        Single(
            "global",
            "Global",
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
                Select("foreground", ColorOptions.LIGHT_ORANGE),
                Select("shade", ColorOptions.GLOBAL),
                Select("size", Sizes.AUTO),
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
            ],
        ),
        Array(
            "gauges",
            "Gauge",
            [
                [
                    Select("data", DataWithValueMax.BODY_BATTERY),
                    Select("accent", ColorOptions.CYAN),
                ],
                [
                    Select("data", DataWithValueMax.STRESS),
                    Select("accent", ColorOptions.YELLOW),
                ],
                [
                    Select("data", DataWithValueMax.MOVE_BAR),
                    Select("accent", ColorOptions.RED),
                ],
            ],
        ),
        Single(
            "top outer",
            "Widget",
            [
                Select("data", widgets.DAWN_OR_DUSK_MOON),
            ],
        ),
        Array(
            "top middle",
            "Metric",
            [
                [
                    Select("data", DataWithIcon.RAIN),
                    Select("width", MetricWidths.AUTO),
                ],
                [
                    Select("data", DataWithIcon.UV_INDEX),
                    Select("width", MetricWidths.AUTO),
                ],
            ],
        ),
        Array(
            "bottom middle",
            "Metric",
            [
                [
                    Select("data", DataAll.HEART_RATE),
                    Select("width", MetricWidths.AUTO),
                ],
                [
                    Select("data", DataAll.STEPS),
                    Select("width", MetricWidths.AUTO),
                ],
            ],
        ),
        Single(
            "bottom outer",
            "Widget",
            [
                Select("data", widgets.BATTERY_ICON),
            ],
        ),
    )


def MemoryMedium(  # pylint: disable=invalid-name
    data: Source,
    widgets: Any,
) -> Settings:
    DataAll = data.all
    DataWithIcon = data.with_icon
    DataWithValueMax = data.with_value_max

    return (
        MemoryLow(data, widgets)
        .extend(
            "status",
            [
                Select("data", Status.NONE),
            ],
        )
        .extend(
            "gauges",
            [
                Select("data", DataWithValueMax.NONE),
                Select("accent", ColorOptions.BLUE),
            ],
        )
        .extend(
            "top middle",
            [
                Select("data", DataWithIcon.WIND),
                Select("width", MetricWidths.AUTO),
            ],
            [
                Select("data", DataWithIcon.NONE),
                Select("width", MetricWidths.AUTO),
            ],
        )
        .extend(
            "bottom middle",
            [
                Select("data", DataAll.FLOORS_CLIMBED),
                Select("width", MetricWidths.AUTO),
            ],
            [
                Select("data", DataAll.NONE),
                Select("width", MetricWidths.AUTO),
            ],
        )
    )


def MemoryHigh(  # pylint: disable=invalid-name
    data: Source,
    widgets: Any,
) -> Settings:
    return MemoryMedium(data, widgets)
