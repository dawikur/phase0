# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from enum import IntEnum, StrEnum, auto
from pathlib import Path
from typing import List

from .data import Data
from .model import Group, Select


class Options(IntEnum):
    AUTO = auto()
    LARGE = auto()
    SMALL = auto()


class Colors(StrEnum):
    BLACK = "0x000000"
    DARK_GRAY = "0x555555"
    LIGHT_GRAY = "0xAAAAAA"
    WHITE = "0xFFFFFF"

    RED = "0xAA0000"
    GREEN = "0x00AA00"
    BLUE = "0x0000AA"

    CYAN = "0x00AAAA"
    MAGENTA = "0xAA00AA"
    YELLOW = "0xAAAA00"

    ORANGE = "0xAA5500"
    PINK = "0xAA0055"
    LIME = "0x55AA00"
    TEAL = "0x00AA55"
    INDIGO = "0x5500AA"
    SKY_BLUE = "0x0055AA"


class Sizes(StrEnum):
    AUTO = str(Options.AUTO.value)
    SMALL = str(Options.SMALL.value)
    LARGE = str(Options.LARGE.value)


COLOR = Select("color", Colors.ORANGE, Colors)
BACKGROUD = Select("background", Colors.DARK_GRAY, Colors)
SIZE = Select("size", Sizes.AUTO, Sizes)


def Settings(data: StrEnum) -> List[Group]:

    return [
        Group(
            "clock",
            [
                COLOR,
                BACKGROUD,
                SIZE,
            ],
        ),
        Group("data", [Select("data", data.HEART_RATE, data)]),  # type: ignore[attr-defined]
    ]
