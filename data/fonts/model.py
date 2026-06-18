# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import textwrap
from dataclasses import dataclass


@dataclass
class Style:
    name: str
    size: int
    weight: int


@dataclass
class Glyph:
    name: str
    bitmap: list[str]

    xoffset: int = 0
    yoffset: int = 0

    width_: int = 0
    xempty_: int = 0

    height_: int = 0
    yempty_: int = 0

    def __post_init__(self) -> None:
        if self.name in ("'", "\\"):
            self.name = f"\\{self.name}"

        self.height_ = len(self.bitmap)
        self.width_ = len(self.bitmap[0]) if self.height_ else 0

        idx = 0
        for row in self.bitmap:
            assert self.width == len(row), textwrap.dedent(f"""\
                Width of each row has to match.
                    glyph == '{self.name}'
                    row[0] == '{self.bitmap[0]}', len == {len(self.bitmap[0])}
                    row[{idx}] == '{row}', len == {len(row)}
            """)
            idx += 1

        while self.is_column_empty_(self.xoffset):
            self.xoffset += 1

        while self.is_column_empty_(self.width_ - self.xempty_ - 1):
            self.xempty_ += 1

        while self.is_row_empty_(self.yoffset):
            self.yoffset += 1

        while self.is_row_empty_(self.height_ - self.yempty_ - 1):
            self.yempty_ += 1

    @property
    def width(self) -> int:
        result = self.width_ - self.xoffset - self.xempty_
        return 0 if result < 0 else result

    @property
    def height(self) -> int:
        result = self.height_ - self.yoffset - self.yempty_
        return 0 if result < 0 else result

    @property
    def xadvance(self) -> int:
        return self.width_

    @property
    def yadvance(self) -> int:
        return self.height_

    def pixel(self, x: int, y: int) -> bool:
        if x < 0 or x >= self.width_ or y < 0 or y >= self.height_:
            return False
        return self.bitmap[y][x] == "1"

    def blure(self) -> "Glyph":
        bitmap = []

        for y in range(self.height_):
            row = ""
            for x in range(self.width_):
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
            bitmap.append(row)

        return Glyph(
            self.name,
            bitmap,
        )

    def is_column_empty_(self, x: int) -> bool:
        if x < 0 or self.width_ <= x:
            return False

        for y in range(self.height_):
            if self.pixel(x, y):
                return False

        return True

    def is_row_empty_(self, y: int) -> bool:
        if y < 0 or self.height_ <= y:
            return False

        for x in range(self.width_):
            if self.pixel(x, y):
                return False

        return True


@dataclass
class Typeface:
    name: str
    glyphs: list[Glyph]
