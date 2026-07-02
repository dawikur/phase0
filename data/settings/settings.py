# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from enum import IntEnum, auto
from typing import Any, cast

from .colors import Colors
from .model import Array, Boolean, Group, Number, Select


class Options(IntEnum):
    ALARM = auto()
    AUTO = auto()
    BLUETOOTH_CONNECTED = auto()
    BLUETOOTH_DISCONNECTED = auto()
    LARGE = auto()
    NOTIFICATIONS = auto()
    SMALL = auto()


class Heights(IntEnum):
    AUTO = Options.AUTO.value
    SMALL = Options.SMALL.value
    LARGE = Options.LARGE.value


class Status(IntEnum):
    ALARM = Options.ALARM.value
    BLUETOOTH_CONNECTED = Options.BLUETOOTH_CONNECTED.value
    BLUETOOTH_DISCONNECTED = Options.BLUETOOTH_DISCONNECTED.value
    NOTIFICATIONS = Options.NOTIFICATIONS.value


class ExtraData(IntEnum):
    BATTERY = auto()
    DATE = auto()
    SUN_MOON = auto()
    WEATHER = auto()


def Settings(  # pylint: disable=invalid-name
    data: IntEnum,
) -> tuple[IntEnum, list[Group | Array]]:
    Extra = cast(
        Any,
        IntEnum("Extra", {datum.name: datum.value + len(data) for datum in ExtraData}),
    )

    Data = cast(
        Any,
        IntEnum(
            "Data",
            {
                **{datum.name: datum.value for datum in data},
                **{datum.name: datum.value for datum in Extra},
            },
        ),
    )

    return Extra, [
        Group(
            "clock",
            [
                Select("color", Colors.LIGHT_ORANGE),
                Select("background", Colors.CHARCOAL),
                Select("height", Heights.AUTO),
            ],
        ),
        Array(
            "status",
            [
                [
                    Select("data", Status.ALARM),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                ],
                [
                    Select("data", Status.BLUETOOTH_CONNECTED),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                ],
                [
                    Select("data", Status.NOTIFICATIONS),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                ],
            ],
        ),
        Array(
            "gauges",
            [
                [
                    Select("data", Data.BODY_BATTERY),
                    Select("color", Colors.CYAN),
                    Select("background", Colors.CHARCOAL),
                ],
                [
                    Select("data", Data.STRESS),
                    Select("color", Colors.YELLOW),
                    Select("background", Colors.CHARCOAL),
                ],
                [
                    Select("data", Data.BODY_BATTERY),
                    Select("color", Colors.RED),
                    Select("background", Colors.CHARCOAL),
                ],
            ],
        ),
        Group(
            "top outer line",
            [
                Select("data", Data.SUN_MOON),
                Select("label", Colors.ORANGE),
                Select("color", Colors.WHITE),
                Select("background", Colors.CHARCOAL),
                Select("height", Heights.AUTO),
            ],
        ),
        Array(
            "top middle line",
            [
                [
                    Select("data", Data.RAIN),
                    Select("label", Colors.ORANGE),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                    Select("height", Heights.AUTO),
                    Number("width", 2),
                    Boolean("icon", True),
                    Boolean("gauge", False),
                ],
                [
                    Select("data", Data.UV),
                    Select("label", Colors.ORANGE),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                    Select("height", Heights.AUTO),
                    Number("width", 2),
                    Boolean("icon", True),
                    Boolean("gauge", False),
                ],
                [
                    Select("data", Data.WIND),
                    Select("label", Colors.ORANGE),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                    Select("height", Heights.AUTO),
                    Number("width", 2),
                    Boolean("icon", True),
                    Boolean("gauge", False),
                ],
            ],
        ),
        Group(
            "top inner line",
            [
                Select("data", Data.WEATHER),
                Select("color", Colors.WHITE),
                Select("background", Colors.CHARCOAL),
                Select("height", Heights.AUTO),
            ],
        ),
        Group(
            "bottom inner line",
            [
                Select("data", Data.DATE),
                Select("color", Colors.WHITE),
                Select("background", Colors.CHARCOAL),
                Select("height", Heights.AUTO),
            ],
        ),
        Array(
            "bottom middle line",
            [
                [
                    Select("data", Data.HEART_RATE),
                    Select("label", Colors.ORANGE),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                    Select("height", Heights.AUTO),
                    Number("width", 3),
                    Boolean("icon", False),
                    Boolean("gauge", True),
                ],
                [
                    Select("data", Data.STEPS),
                    Select("label", Colors.ORANGE),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                    Select("height", Heights.AUTO),
                    Number("width", 3),
                    Boolean("icon", False),
                    Boolean("gauge", True),
                ],
                [
                    Select("data", Data.FLOORS_CLIMBED),
                    Select("label", Colors.ORANGE),
                    Select("color", Colors.WHITE),
                    Select("background", Colors.CHARCOAL),
                    Select("height", Heights.AUTO),
                    Number("width", 3),
                    Boolean("icon", False),
                    Boolean("gauge", True),
                ],
            ],
        ),
        Group(
            "bottom outer line",
            [
                Select("data", Data.BATTERY),
                Select("color", Colors.WHITE),
                Select("background", Colors.CHARCOAL),
                Select("height", Heights.AUTO),
            ],
        ),
    ]
