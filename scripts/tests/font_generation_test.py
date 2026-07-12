# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from data.fonts.model import Glyph as SourceGlyph
from data.fonts.model import Style, Typeface
from scripts.utils.font_generation import Fnt, parse_typeface_and_style


def test_fnt_omits_empty_glyph_dimensions_but_keeps_advance() -> None:
    fnt = Fnt(name="sample", atlas_w=1, atlas_h=1, line_h=1)

    fnt.add(
        name=" ",
        atlas_x=0,
        atlas_y=0,
        width=0,
        height=1,
        xoffset=3,
        yoffset=4,
        xadvance=5,
    )

    assert "width=0 height=0 xoffset=0 yoffset=0 xadvance=5" in str(fnt)


def test_parse_typeface_and_style_filters_required_glyphs() -> None:
    typeface = Typeface(
        "Sample",
        [
            SourceGlyph("A", ["10", "11"]),
            SourceGlyph("B", ["01", "11"]),
        ],
    )
    style = Style("Regular", size=2, weight=1)

    name, atlas, fnt, comments = parse_typeface_and_style(
        typeface,
        style,
        required_glyphs={"B"},
    )

    assert name == "sample_regular"
    assert atlas.size == (4, 4)
    assert "chars count=1" in fnt
    assert "char id=66" in fnt
    assert "char id=65" not in fnt
    assert comments == {"B": ""}
