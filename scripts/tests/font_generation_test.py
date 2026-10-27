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
from scripts.utils.burn_in import BitmapFont
from scripts.utils.font_generation import (
    generate_fonts,
    get_required_glyphs,
    parse_typeface_and_style,
)


def test_generated_font_can_render_filtered_glyphs_and_spaces(tmp_path: Path) -> None:
    typeface = Typeface(
        "Sample",
        [
            SourceGlyph("A", ["10", "11"]),
            SourceGlyph("B", ["01", "11"]),
            SourceGlyph(" ", ["00", "00"]),
        ],
    )
    _, atlas, fnt, _ = parse_typeface_and_style(
        typeface, Style("Regular", size=2, weight=1), required_glyphs="B "
    )
    atlas.save(tmp_path / "sample.png")
    (tmp_path / "sample.fnt").write_text(fnt)
    font = BitmapFont.read(tmp_path, "sample")

    assert set(font.glyphs) == {ord("B"), ord(" ")}
    assert font.glyphs[ord("B")] == {(2, 0), (0, 2), (2, 2)}
    assert font.glyphs[ord(" ")] == set()
    advance = font.advances[ord("B")] + font.advances[ord(" ")]
    assert font.text("B B") == font.glyphs[ord("B")] | {
        (x + advance, y) for x, y in font.glyphs[ord("B")]
    }
    assert font.advances[ord(" ")] == 5
    with pytest.raises(KeyError):
        font.text("A")


def test_parse_typeface_and_style_requires_name_for_multiple_typefaces() -> None:
    style = Style("Regular", size=1, weight=1)
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


def assert_generated_font_matches(
    output: Path,
    typeface: Typeface,
    style: Style,
    name: str,
    required_glyphs: str | None,
) -> None:
    font = BitmapFont.read(output, name)
    glyphs = {
        (32 + index if glyph.name.startswith("#") else ord(glyph.name[0])): glyph
        for index, glyph in enumerate(
            sorted(typeface.glyphs, key=lambda item: item.name)
        )
        if required_glyphs is None or glyph.name[0] in required_glyphs
    }
    assert set(font.glyphs) == set(glyphs)
    for char, glyph in glyphs.items():
        expected = {
            (x * style.size + dx, y * style.size + dy)
            for y, row in enumerate(glyph.bitmap)
            for x, pixel in enumerate(row)
            if pixel == "1"
            for dx in range(style.weight)
            for dy in range(style.weight)
        }
        assert font.glyphs[char] == expected
        assert font.advances[char] == glyph.xadvance * style.size + 1


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
            case[3].upper() for case in cases if case[3] != "icons"
        }
        assert all(item.attrib["antialias"] == "false" for item in definitions)
        for case in cases:
            font_output = (
                folders.resources(f"memory/high/generated/fonts/{profile}")
                if case[3] == "icons"
                else output
            )
            assert_generated_font_matches(
                font_output, case[0], case[style_index], case[3], case[4]
            )


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


def test_icon_memory_profiles_share_character_ids_and_omit_conditions(
    tmp_path: Path,
) -> None:
    folders = Folders(tmp_path / "build", tmp_path / "resources", tmp_path / "source")
    # Old shared atlases must disappear when regenerating resources.
    for profile in ("mip", "amoled"):
        for filename in ("icons.png", "icons.fnt"):
            folders.resources(f"fonts/{profile}/generated", filename).write_text("old")
    generate_fonts(folders, "0123456789")
    for profile, style in [("mip", fonts.STYLE_2), ("amoled", fonts.STYLE_3)]:
        low = folders.resources(f"memory/low/generated/fonts/{profile}")
        high = folders.resources(f"memory/high/generated/fonts/{profile}")
        low_font = BitmapFont.read(low, "icons")
        full_font = BitmapFont.read(high, "icons")
        assert len(low_font.glyphs) == 34
        assert len(full_font.glyphs) - len(low_font.glyphs) == 57
        for char, mask in low_font.glyphs.items():
            assert full_font.glyphs[char] == mask
            assert full_font.advances[char] == low_font.advances[char]
        assert_generated_font_matches(
            low, fonts.TYPEFACE_ICONS_GENERAL, style, "icons", None
        )
        with (
            Image.open(low / "icons.png") as actual,
            Image.open(high / "icons.png") as full,
        ):
            assert actual.size == ((462, 18) if profile == "mip" else (693, 27))
            assert full.size == ((1242, 22) if profile == "mip" else (1863, 33))
            assert actual.width * actual.height < full.width * full.height
        for filename in ("icons.fnt", "icons.png", "fonts.xml"):
            assert (
                folders.resources(
                    f"memory/medium/generated/fonts/{profile}", filename
                ).read_bytes()
                == (high / filename).read_bytes()
            )
        assert [
            item.attrib["id"] for item in ET.parse(low / "fonts.xml").getroot()
        ] == ["ICONS"]
        assert not folders.resources(f"fonts/{profile}/generated", "icons.png").exists()
        assert not folders.resources(f"fonts/{profile}/generated", "icons.fnt").exists()


def test_empty_typeface_renders_empty_text(tmp_path: Path) -> None:
    name, atlas, fnt, comments = parse_typeface_and_style([], [], name="Empty")
    assert name == "empty"
    assert atlas.size == (0, 0)
    assert not comments
    # PNG cannot represent a zero-sized image. The consumer only needs a pixel
    # when a glyph exists, so supply an empty backing image for this case.
    Image.new("1", (1, 1)).save(tmp_path / "empty.png")
    (tmp_path / "empty.fnt").write_text(fnt)
    font = BitmapFont.read(tmp_path, "empty")
    assert font.text("") == set()
    with pytest.raises(KeyError):
        font.text("A")
