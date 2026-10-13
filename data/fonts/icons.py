# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from .icons_extra import GLYPHS as EXTRA_GLYPHS
from .icons_general import GLYPHS as GENERAL_GLYPHS
from .icons_general import ICON
from .model import Glyph, Typeface

TYPEFACE = Typeface("Icons", GENERAL_GLYPHS + EXTRA_GLYPHS)

# Use the full font's character IDs even when conditions glyphs are omitted.
EXTRA_NAMES = {glyph.name[1:] for glyph in EXTRA_GLYPHS}
TYPEFACE_GENERAL = Typeface(
    "Icons",
    [
        Glyph(chr(ord(" ") + index) + glyph.name[1:], glyph.bitmap)
        for index, glyph in enumerate(
            sorted(TYPEFACE.glyphs, key=lambda item: item.name)
        )
        if glyph.name[1:] not in EXTRA_NAMES
    ],
)

__all__ = ["ICON", "TYPEFACE"]
