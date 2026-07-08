# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from enum import IntEnum


class Colors(IntEnum):
    # sorted by lightness
    BLACK = 0x000000  # 0.00
    CHARCOAL = 0x555555  # 0.33
    SILVER = 0xAAAAAA  # 0.67
    WHITE = 0xFFFFFF  # 1.00

    # sorted by hue
    RED = 0xAA0000  #   0
    ORANGE = 0xAA5500  #  30
    YELLOW = 0xAAAA00  #  60
    GREEN = 0x55AA00  #  90
    CYAN = 0x00AAAA  # 180
    AZURE = 0x0055AA  # 210
    BLUE = 0x0000AA  # 240
    INDIGO = 0x5500AA  # 270
    MAGENTA = 0xAA00AA  # 300
    PINK = 0xAA0055  # 330

    LIGHT_RED = 0xFF5555  # 0
    LIGHT_ORANGE = 0xFFAA00  # 40
    LIGHT_YELLOW = 0xFFFF55  # 60
    LIGHT_GREEN = 0x55FF55  # 120
    LIGHT_CYAN = 0x55FFFF  # 180
    LIGHT_AZURE = 0x55AAFF  # 210
    LIGHT_BLUE = 0x5555FF  # 240
    LIGHT_INDIGO = 0xAA55FF  # 270
    LIGHT_MAGENTA = 0xFF55FF  # 300
    LIGHT_PINK = 0xFF55AA  # 330
