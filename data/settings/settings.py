# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import IntEnum, auto
from typing import Any, cast

from .colors import Colors
from .data import Data
from .model import Array, Number, Select, Settings, Single


class Options(IntEnum):
    NONE = auto()

    ALARM = auto()
    AUTO = auto()
    BATTERY_DAYS_REMAINING = auto()
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


class Heights(IntEnum):
    AUTO = Options.AUTO.value
    SMALL = Options.SMALL.value


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
    data: Data,
) -> type[IntEnum]:
    DataWidget = cast(
        Any,
        IntEnum(
            "Widget",
            {
                datum.name: datum.value + len(data)
                for datum in [
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
            },
        ),
    )

    return DataWidget


def MemoryLow(  # pylint: disable=invalid-name
    data: Data,
    widgets: Any,
) -> Settings:
    DataAll = data.all
    DataWithIcon = data.with_icon
    DataWithValueMax = data.with_value_max

    return Settings(
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
            ],
        ),
        Single(
            "top outer",
            "Widget",
            [
                Select("data", widgets.DAWN_AND_DUSK_MOON),
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
            ],
        ),
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
    data: Data,
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
                Select("accent", Colors.BLUE),
            ],
        )
        .extend(
            "top middle",
            [
                Select("data", DataWithIcon.WIND),
                Number("width", 2),
            ],
            [
                Select("data", DataWithIcon.NONE),
                Number("width", 2),
            ],
        )
        .extend(
            "bottom middle",
            [
                Select("data", DataAll.FLOORS_CLIMBED),
                Number("width", 3),
            ],
            [
                Select("data", DataAll.NONE),
                Number("width", 3),
            ],
        )
    )


def MemoryHigh(  # pylint: disable=invalid-name
    data: Data,
    widgets: Any,
) -> Settings:
    return MemoryMedium(data, widgets)
