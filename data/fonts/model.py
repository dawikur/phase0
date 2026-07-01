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

    __width: int = 0
    __xempty: int = 0

    __height: int = 0
    __yempty: int = 0

    def __post_init__(self) -> None:
        if self.name in ("'", "\\"):
            self.name = f"\\{self.name}"

        self.__height = len(self.bitmap)
        self.__width = len(self.bitmap[0]) if self.__height else 0

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

        while self.is_column_empty_(self.__width - self.__xempty - 1):
            self.__xempty += 1

        while self.is_row_empty_(self.yoffset):
            self.yoffset += 1

        while self.is_row_empty_(self.__height - self.__yempty - 1):
            self.__yempty += 1

    @property
    def width(self) -> int:
        result = self.__width - self.xoffset - self.__xempty
        return 0 if result < 0 else result

    @property
    def height(self) -> int:
        result = self.__height - self.yoffset - self.__yempty
        return 0 if result < 0 else result

    @property
    def xadvance(self) -> int:
        return self.__width

    @property
    def yadvance(self) -> int:
        return self.__height

    def pixel(self, x: int, y: int) -> bool:
        if x < 0 or x >= self.__width or y < 0 or y >= self.__height:
            return False
        return self.bitmap[y][x] == "1"

    def blure(self) -> "Glyph":
        bitmap = []

        for y in range(self.__height):
            row = ""
            for x in range(self.__width):
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
        if x < 0 or self.__width <= x:
            return False

        for y in range(self.__height):
            if self.pixel(x, y):
                return False

        return True

    def is_row_empty_(self, y: int) -> bool:
        if y < 0 or self.__height <= y:
            return False

        for x in range(self.__width):
            if self.pixel(x, y):
                return False

        return True


@dataclass
class Typeface:
    name: str
    glyphs: list[Glyph]
