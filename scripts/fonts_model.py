# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import textwrap
from dataclasses import dataclass
from typing import List


@dataclass
class Style:
    name: str
    size: int
    weight: int


@dataclass
class Glyph:
    name: str
    bitmap: list[str]

    def __post_init__(self) -> None:
        if self.name == "'" or self.name == "\\":
            self.name = f"\\{self.name}"

        idx = 0
        for row in self.bitmap:
            assert self.width == len(row), textwrap.dedent(
                f"""\
                Width of each row has to match.
                    glyph == '{self.name}'
                    row[0] == '{self.bitmap[0]}', len == {len(self.bitmap[0])}
                    row[{idx}] == '{row}', len == {len(row)}
            """
            )
            idx += 1

    @property
    def height(self) -> int:
        return len(self.bitmap)

    @property
    def width(self) -> int:
        if self.height == 0:
            return 0
        return len(self.bitmap[0])

    def pixel(self, x: int, y: int) -> bool:
        if x < 0 or x >= self.width or y < 0 or y >= self.height:
            return False
        return self.bitmap[y][x] == "1"

    def blure(self) -> "Glyph":
        new_width = self.width
        new_height = self.height
        new_bitmap = []

        for y in range(new_height):
            row = ""
            for x in range(new_width):
                neighbors = [
                    (x, y),  # self
                    (x - 1, y),  # left
                    (x + 1, y),  # right
                    (x, y - 1),  # up
                    (x, y + 1),  # down
                ]
                if any(self.pixel(nx, ny) for nx, ny in neighbors):
                    row += "1"
                else:
                    row += "0"
            new_bitmap.append(row)

        return Glyph(
            self.name,
            new_bitmap,
        )


@dataclass
class Typeface:
    name: str
    glyphs: List[Glyph]
