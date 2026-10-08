# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import xml.etree.ElementTree as ET
from pathlib import Path
from unittest.mock import patch

import pytest
from PIL import Image

from data import fonts
from data.fonts.model import Glyph as SourceGlyph
from data.fonts.model import Style, Typeface
from scripts.utils.args_parse import Folders, parse_folders
from scripts.utils.font_generation import (
    Fnt,
    generate_fonts,
    get_required_glyphs,
    parse_typeface_and_style,
)


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
        required_glyphs="B",
    )

    assert name == "sample_regular"
    assert atlas.size == (4, 4)
    assert "chars count=1" in fnt
    assert "char id=66" in fnt
    assert "char id=65" not in fnt
    assert comments == {"B": ""}


def test_parse_typeface_and_style_supports_empty_and_multiple_typefaces() -> None:
    style = Style("Regular", size=1, weight=1)

    name, atlas, fnt, comments = parse_typeface_and_style([], [], name="Empty")

    assert (name, atlas.size, comments) == ("empty", (0, 0), {})
    assert "chars count=0" in fnt

    typeface = Typeface("Sample", [SourceGlyph("A", ["1"])])
    with pytest.raises(AssertionError, match="Name is required"):
        parse_typeface_and_style([typeface, typeface], [style, style])


def test_generate_fonts_writes_all_generated_outputs(tmp_path) -> None:
    resources = tmp_path / "resources"
    resources.joinpath("base").mkdir(parents=True)
    resources.joinpath("base/strings.xml").write_text(
        '<resources><string id="HELLO">Hi</string></resources>',
        encoding="utf-8",
    )
    folders = Folders(tmp_path / "build", resources, tmp_path / "source")

    required_glyphs = get_required_glyphs(folders)
    generate_fonts(folders, required_glyphs)

    assert folders.source("generated", "fonts.mc").exists()
    assert folders.resources("fonts/mip/generated", "fonts.xml").exists()
    assert folders.resources("fonts/amoled/generated", "fonts.xml").exists()
    assert not folders.resources("base/generated", "fonts.xml").exists()


def test_folders_and_parse_folders_resolve_output_paths(tmp_path, monkeypatch) -> None:
    folders = Folders(tmp_path / "build", tmp_path / "resources", tmp_path / "source")

    assert folders.build() == tmp_path / "build"
    assert folders.resources("base/generated", "fonts.xml") == (
        tmp_path / "resources" / "base" / "generated" / "fonts.xml"
    )
    assert folders.source("data") == tmp_path / "source" / "data"

    monkeypatch.setattr(
        "sys.argv",
        ["generate", "--build", "b", "--resources", "r", "--source", "s"],
    )
    assert parse_folders().build_ == Path("b")


def test_required_glyphs_reports_invalid_and_missing_strings(tmp_path, capsys) -> None:
    resources = tmp_path / "resources" / "base"
    resources.mkdir(parents=True)
    resources.joinpath("strings.xml").write_text(
        '<resources><string id="A">🦄</string></resources>', encoding="utf-8"
    )
    folders = Folders(tmp_path / "build", tmp_path / "resources", tmp_path / "source")

    get_required_glyphs(folders)
    assert "Missing glyphs" in capsys.readouterr().out

    resources.joinpath("strings.xml").write_text("<resources>", encoding="utf-8")
    get_required_glyphs(folders)
    assert "XML parse error" in capsys.readouterr().out

    with patch(
        "scripts.utils.font_generation.ET.parse", side_effect=RuntimeError("boom")
    ):
        get_required_glyphs(folders)
    assert "Error reading" in capsys.readouterr().out


def test_generated_profiles_preserve_ids_glyphs_and_mip_bitmaps(tmp_path: Path) -> None:
    folders = Folders(tmp_path / "build", tmp_path / "resources", tmp_path / "source")
    legacy = folders.resources("base/generated")
    (legacy / "fonts.xml").write_text("old")
    (legacy / "icons.png").write_text("old")
    (legacy / "unrelated.xml").write_text("keep")
    generate_fonts(folders, "012AB ")
    assert (legacy / "unrelated.xml").read_text() == "keep"
    assert not (legacy / "icons.png").exists()
    cases = [
        (
            fonts.TYPEFACE_DIGITS,
            fonts.STYLE_3,
            fonts.STYLE_4,
            "digits_regular",
            ":0123456789",
        ),
        (
            fonts.TYPEFACE_DIGITS,
            fonts.STYLE_3_THIN,
            fonts.STYLE_4_THIN,
            "digits_regular_thin",
            ":8",
        ),
        (
            fonts.TYPEFACE_DIGITS_SMALL,
            fonts.STYLE_3,
            fonts.STYLE_4,
            "digits_small",
            ":0123456789",
        ),
        (
            fonts.TYPEFACE_DIGITS_SMALL,
            fonts.STYLE_3_THIN,
            fonts.STYLE_4_THIN,
            "digits_small_thin",
            ":8",
        ),
        (
            fonts.TYPEFACE_DOT,
            fonts.STYLE_3,
            fonts.STYLE_4,
            "dot_regular",
            "012AB ",
        ),
        (
            fonts.TYPEFACE_DOT,
            fonts.STYLE_3_THIN,
            fonts.STYLE_4_THIN,
            "dot_regular_thin",
            "012AB ",
        ),
        (
            fonts.TYPEFACE_DOT,
            fonts.STYLE_2,
            fonts.STYLE_3,
            "dot_small",
            "012AB ",
        ),
        (
            fonts.TYPEFACE_DOT,
            fonts.STYLE_1,
            fonts.STYLE_2_BOLD,
            "dot_tiny",
            "012AB ",
        ),
        (fonts.TYPEFACE_ICONS, fonts.STYLE_2, fonts.STYLE_3, "icons", None),
    ]
    for profile, style_index in [("mip", 1), ("amoled", 2)]:
        output = folders.resources(f"fonts/{profile}/generated")
        definitions = ET.parse(output / "fonts.xml").getroot()
        assert {item.attrib["id"] for item in definitions} == {
            case[3].upper() for case in cases
        }
        assert all(item.attrib["antialias"] == "false" for item in definitions)
        for case in cases:
            _, expected_atlas, expected_fnt, _ = parse_typeface_and_style(
                case[0], case[style_index], case[3], case[4]
            )
            assert (output / f"{case[3]}.fnt").read_text() == expected_fnt
            with Image.open(output / f"{case[3]}.png") as actual:
                assert actual.size == expected_atlas.size
                assert actual.tobytes() == expected_atlas.tobytes()
    source = folders.source("generated", "display.mc").read_text()
    assert "module Display {" in source
    assert "(:display_mip)\n\tconst IS_AMOLED as Lang.Boolean = false;" in source
    assert "(:display_amoled)\n\tconst IS_AMOLED as Lang.Boolean = true;" in source
    source = folders.source("generated", "fonts.mc").read_text()
    assert "IS_AMOLED" not in source
    for name, size in [("REGULAR", 3), ("SMALL", 2), ("TINY", 1)]:
        assert f"(:display_mip)\n\tconst SPACING_{name} = {size};" in source
        assert f"(:display_amoled)\n\tconst SPACING_{name} = {size + 1};" in source


@pytest.mark.parametrize(
    "style",
    [
        fonts.STYLE_4,
        fonts.STYLE_4_THIN,
        fonts.STYLE_3,
        fonts.STYLE_2_BOLD,
    ],
)
def test_larger_styles_draw_exact_pixel_blocks(style: Style) -> None:
    typeface = Typeface("Sample", [SourceGlyph("A", ["101", "000", "101"])])
    _, atlas, _, _ = parse_typeface_and_style(typeface, style)
    for y in range(3 * style.size):
        for x in range(3 * style.size):
            expected = (
                x // style.size in (0, 2)
                and y // style.size in (0, 2)
                and x % style.size < style.weight
                and y % style.size < style.weight
            )
            assert bool(atlas.getpixel((x, y))) == expected
