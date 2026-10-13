# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from .icons_conditions import GLYPHS as CONDITION_GLYPHS
from .icons_general import GLYPHS as GENERAL_GLYPHS
from .icons_general import ICON
from .model import Typeface

TYPEFACE = Typeface("Icons", GENERAL_GLYPHS + CONDITION_GLYPHS)

__all__ = ["ICON", "TYPEFACE"]
