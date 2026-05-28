# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from .model import Group, Select, Settings

# fmt: off

COLOR_OPTIONS = [
    "black",
    "dark gray",
    "light gray",
    "white",

    "red",
    "green",
    "blue",

    "cyan",
    "magenta",
    "yellow",

    "orange",
    "pink",
    "lime",

    "teal",
    "indigo",
    "sky blue",
]

COLOR = Select("color", COLOR_OPTIONS)
BACKGROUD = Select("background", COLOR_OPTIONS)
SIZE = Select("size", [
    "auto",
    "regular",
    "small",
])

SETTINGS = Settings([
    Group("clock", [
        COLOR,
        BACKGROUD,
        SIZE,
    ]),
])
