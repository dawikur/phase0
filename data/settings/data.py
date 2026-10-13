# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from collections.abc import Iterable
from enum import IntEnum, auto, unique
from typing import Any, cast

from .colors import Colors
from .model import Array, Boolean, Select, Settings, Single
from .options import StableOptions
from .source import Datum, Source


@unique
class Options(StableOptions):
    AUTO = -1
    NONE = 0

    ALARM = auto()
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
    NONE = Options.NONE.value
    WIDTH_1 = auto()
    WIDTH_2 = auto()
    WIDTH_3 = auto()
    WIDTH_4 = auto()
    WIDTH_5 = auto()
    WIDTH_6 = auto()
    WIDTH_7 = auto()
    WIDTH_8 = auto()
    WIDTH_9 = auto()
    WIDTH_10 = auto()

class MetricStyle(IntEnum):
    AUTO = Options.AUTO.value
    NONE = Options.NONE.value

    ICON = Options.ICON.value
    GAUGE = Options.GAUGE.value


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


def Widgets(  # pylint: disable=invalid-name
    data: Iterable[Datum],
) -> type[IntEnum]:
    data_ids = {datum.value for datum in data}
    for option in EXTRA_WIDGETS:
        if option.value in data_ids:
            raise ValueError(f"Widget ID collision for {option.name}: {option.value}")
    DataWidget = cast(
        Any,
        IntEnum(
            "Widget",
            {datum.name: datum.value for datum in EXTRA_WIDGETS},
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
                [
                    Select("data", Status.NONE),
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
                [
                    Select("data", DataWithValueMax.NONE),
                    Select("accent", ColorOptions.BLUE),
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
                    Select("data", DataAll.RAIN),
                    Select("width", MetricWidths.AUTO),
                    Select("style", MetricStyle.AUTO),
                ],
                [
                    Select("data", DataAll.UV_INDEX),
                    Select("width", MetricWidths.AUTO),
                    Select("style", MetricStyle.AUTO),
                ],
                [
                    Select("data", DataAll.WIND),
                    Select("width", MetricWidths.AUTO),
                    Select("style", MetricStyle.AUTO),
                ],
                [
                    Select("data", DataAll.NONE),
                    Select("width", MetricWidths.AUTO),
                    Select("style", MetricStyle.AUTO),
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
                    Select("style", MetricStyle.AUTO),
                ],
                [
                    Select("data", DataAll.STEPS),
                    Select("width", MetricWidths.AUTO),
                    Select("style", MetricStyle.AUTO),
                ],
                [
                    Select("data", DataAll.FLOORS_CLIMBED),
                    Select("width", MetricWidths.AUTO),
                    Select("style", MetricStyle.AUTO),
                ],
                [
                    Select("data", DataAll.NONE),
                    Select("width", MetricWidths.AUTO),
                    Select("style", MetricStyle.AUTO),
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


def MemoryHigh(  # pylint: disable=invalid-name
    data: Source,
    widgets: Any,
) -> Settings:
    return MemoryMedium(data, widgets)
