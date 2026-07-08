# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from enum import IntEnum, auto
from typing import Any, cast

from .colors import Colors
from .model import Array, Select, Single  # , Boolean, Number


class Options(IntEnum):
    ALARM = auto()
    AUTO = auto()
    BLUETOOTH_CONNECTED = auto()
    BLUETOOTH_DISCONNECTED = auto()
    ICON = auto()
    LARGE = auto()
    NOTIFICATIONS = auto()
    PERCENTAGE = auto()
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


class Battery(IntEnum):
    ICON = Options.ICON.value
    PERCENTAGE = Options.PERCENTAGE.value


class ExtraData(IntEnum):
    BATTERY = auto()
    DATE = auto()
    SUN_MOON = auto()
    WEATHER = auto()


def Settings(  # pylint: disable=invalid-name
    data: IntEnum,
) -> tuple[IntEnum, list[Single | Array]]:
    Extra = cast(
        Any,
        IntEnum("Extra", {datum.name: datum.value + len(data) for datum in ExtraData}),
    )

    # Data = cast(
    #    Any,
    #    IntEnum(
    #        "Data",
    #        {
    #            **{datum.name: datum.value for datum in data},
    #            **{datum.name: datum.value for datum in Extra},
    #        },
    #    ),
    # )

    return Extra, [
        Single(
            "clock",
            [
                Select("color", Colors.LIGHT_ORANGE),
                Select("background", Colors.CHARCOAL),
                Select("height", Heights.AUTO),
            ],
        ),
        Single(
            "battery",
            [
                Select("data", Battery.ICON),
                Select("color", Colors.WHITE),
                Select("charging", Colors.CHARCOAL),
            ],
        ),
    ]
