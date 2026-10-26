# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Choose minute offsets from the actual AMOLED bitmap fonts.

This checks static masks, not device luminance or arbitrary widget overlap.
Keep the samples and shadow geometry aligned with minimal rendering.
"""

import itertools
import re
from dataclasses import dataclass
from functools import reduce
from pathlib import Path

from PIL import Image

from data import fonts
from scripts.utils.mc_document import McDocument, McScope

Point = tuple[int, int]
Mask = frozenset[Point]
Cycle = tuple[Point, ...]


@dataclass
class BitmapFont:
    glyphs: dict[int, Mask]
    advances: dict[int, int]

    @classmethod
    def read(cls, folder: Path, name: str) -> "BitmapFont":
        glyphs = {}
        advances = {}
        with Image.open(folder / f"{name}.png") as atlas:
            for line in (folder / f"{name}.fnt").read_text().splitlines():
                if not line.startswith("char "):
                    continue
                fields = {
                    key: int(value) for key, value in re.findall(r"(\w+)=(-?\d+)", line)
                }
                char = fields["id"]
                advances[char] = fields["xadvance"]
                glyphs[char] = frozenset(
                    (x + fields["xoffset"], y + fields["yoffset"])
                    for y in range(fields["height"])
                    for x in range(fields["width"])
                    if atlas.getpixel((fields["x"] + x, fields["y"] + y))
                )
        return cls(glyphs, advances)

    def text(self, value: str) -> Mask:
        pixels: set[Point] = set()
        pos_x = 0
        for char in value:
            pixels.update(translate(self.glyphs[ord(char)], (pos_x, 0)))
            pos_x += self.advances[ord(char)]
        return frozenset(pixels)


def translate(mask: Mask, offset: Point) -> Mask:
    return frozenset((x + offset[0], y + offset[1]) for x, y in mask)


def with_shadow(mask: Mask, shadow: int) -> Mask:
    return mask | translate(mask, (shadow, shadow))


def minimal_masks(
    folder: Path, shadow: int, icons_folder: Path | None = None
) -> list[Mask]:
    masks: set[Mask] = set()
    for name in ("digits_regular", "digits_small", "icons", "dot_small"):
        font = BitmapFont.read(
            icons_folder if name == "icons" and icons_folder else folder, name
        )
        # Dot is shared with normal rendering and translated labels. Minimal
        # battery text uses only digits and remaining-time suffixes; unrelated
        # glyphs must not constrain its offset cycle.
        if name != "dot_small":
            masks.update(font.glyphs.values())
        if name.startswith("digits_"):
            # Fixed clock slots: include every possible digit at each position,
            # so changing the time cannot fill a hole between cycle phases.
            digits = frozenset().union(
                *(font.glyphs[ord(char)] for char in "0123456789")
            )
            pixels: set[Point] = set()
            pos_x = 0
            for char in "00:00":
                pixels.update(
                    translate(
                        font.glyphs[ord(char)] if char == ":" else digits, (pos_x, 0)
                    )
                )
                pos_x += font.advances[ord(char)]
            masks.add(frozenset(pixels))
        elif name == "dot_small":
            masks.update(
                with_shadow(font.glyphs[ord(char)], shadow)
                for char in "0123456789dhm"
                if ord(char) in font.glyphs
            )
            # Percentages and representative remaining-time values, including
            # suffixes and adjacent characters with their actual advances.
            values = itertools.chain(
                (str(value) for value in range(101)),
                (f"{value}{suffix}" for value in range(1000) for suffix in "dhm"),
            )
            masks.update(
                with_shadow(font.text(value), shadow)
                for value in values
                if all(ord(char) in font.glyphs for char in value)
            )
        else:
            # Battery fill in the foreground; its frame remains a shadow in AoD.
            icons = {
                glyph.name[1:]: chr(ord(" ") + index)
                for index, glyph in enumerate(
                    sorted(fonts.TYPEFACE_ICONS.glyphs, key=lambda glyph: glyph.name)
                )
            }
            for bars in range(1, 33):
                masks.add(
                    font.text(
                        icons["battery empty"]
                        + icons["battery charge"] * bars
                        + icons["battery empty"]
                    )
                    | translate(
                        font.text(
                            icons["battery begin"]
                            + icons["battery frame"] * bars
                            + icons["battery end"]
                        ),
                        (shadow, shadow),
                    )
                )
    masks.discard(frozenset())
    return sorted(masks, key=lambda mask: (-len(mask), sorted(mask)))


def find_cycle(masks: list[Mask], max_offset: int = 2) -> Cycle:
    """Find up to four phases; every pixel must be black in at least one.

    Search by increasing displacement, then phase count, deterministically.
    Four minute-long phases permit at most three consecutive lit minutes for
    a static mask. Refuse unverified offsets instead of silently falling back.
    """
    if not masks or any(not mask for mask in masks) or max_offset < 0:
        raise ValueError("Expected nonempty masks and a nonnegative offset limit")
    min_x = min(x for mask in masks for x, _ in mask)
    min_y = min(y for mask in masks for _, y in mask)
    width = max(x for mask in masks for x, _ in mask) - min_x + 2 * max_offset + 1
    # Encode each mask once. Padding makes whole-integer shifts equivalent to
    # translating the bitmap, without wrapping pixels across row boundaries.
    encoded = [
        sum(
            1 << ((y - min_y + max_offset) * width + x - min_x + max_offset)
            for x, y in mask
        )
        for mask in masks
    ]
    for radius in range(max_offset + 1):
        positions: list[Point] = [
            (x, y)
            for x in range(-radius, radius + 1)
            for y in range(-radius, radius + 1)
        ]
        shifted = [
            [
                (
                    bits << (dy * width + dx)
                    if 0 <= dy * width + dx
                    else bits >> -(dy * width + dx)
                )
                for dx, dy in positions
            ]
            for bits in encoded
        ]
        for count in range(1, min(4, len(positions)) + 1):
            for indices in itertools.combinations(range(len(positions)), count):
                if all(
                    not reduce(int.__and__, (variants[index] for index in indices))
                    for variants in shifted
                ):
                    points = tuple(positions[index] for index in indices)
                    # The set determines coverage; order it to reduce movement.
                    return min(itertools.permutations(points), key=_movement)
    raise ValueError(
        f"No burn-in cycle within ±{max_offset} px and four minute phases; "
        "review AMOLED fonts, shadows or the offset limit"
    )


def _movement(cycle: Cycle) -> tuple[int, int, Cycle]:
    steps = [
        tuple(a - b for a, b in zip(cycle[index], cycle[(index + 1) % len(cycle)]))
        for index in range(len(cycle))
    ]
    return (
        max(max(abs(x), abs(y)) for x, y in steps),
        sum(x * x + y * y for x, y in steps),
        cycle,
    )


def generate_burn_in(
    folder: Path, output: Path, shadow: int, icons_folder: Path | None = None
) -> Cycle:
    cycle = find_cycle(minimal_masks(folder, shadow, icons_folder))
    document = McDocument.create()
    document.line("import Toybox.Lang;")
    document.line()
    document.line("// Generated from AMOLED font masks and minimal-rendering shadows.")
    document.line(
        "// Static-mask coverage only; validate luminance and layout on device."
    )
    document.line("(:display_amoled)")
    with McScope(document, "module BurnIn {"):
        document.line(f"const PHASE_COUNT = {len(cycle)};")
        document.line(
            "const OFFSETS_X as Lang.Array<Lang.Number> = ["
            + ", ".join(str(x) for x, _ in cycle)
            + "];"
        )
        document.line(
            "const OFFSETS_Y as Lang.Array<Lang.Number> = ["
            + ", ".join(str(y) for _, y in cycle)
            + "];"
        )
    output.write_text(document.render())
    return cycle
