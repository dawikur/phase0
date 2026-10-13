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


def assert_generated_font_matches(
    output: Path,
    typeface: Typeface,
    style: Style,
    name: str,
    required_glyphs: str | None,
) -> None:
    _, expected_atlas, expected_fnt, _ = parse_typeface_and_style(
        typeface, style, name, required_glyphs
    )
    assert (output / f"{name}.fnt").read_text() == expected_fnt
    with Image.open(output / f"{name}.png") as actual:
        assert actual.size == expected_atlas.size
        assert actual.tobytes() == expected_atlas.tobytes()


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
    source = folders.source("generated", "display.mc").read_text()
    assert "module Display {" in source
    assert "(:display_mip)\n\tconst IS_AMOLED as Lang.Boolean = false;" in source
    assert "(:display_amoled)\n\tconst IS_AMOLED as Lang.Boolean = true;" in source
    source = folders.source("generated", "fonts.mc").read_text()
    for name in (
        "TEMPERATURE_0",
        "TEMPERATURE_1",
        "TEMPERATURE_2",
        "TEMPERATURE_3",
        "TEMPERATURE_4",
        "TEMPERATURE_5",
        "TEMPERATURE_6",
        "MOVE_BAR_0",
        "MOVE_BAR_1",
        "MOVE_BAR_2",
        "MOVE_BAR_3",
        "MOVE_BAR_4",
        "MOVE_BAR_5",
        "BATTERY_0",
        "BATTERY_1",
        "BATTERY_2",
        "BATTERY_3",
        "BATTERY_4",
        "SOLAR_0",
        "SOLAR_1",
        "SOLAR_2",
        "SOLAR_3",
        "SOLAR_4",
    ):
        assert source.count(f"const ICON_{name} =") == 1
    assert "ICON_UV_" not in source
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


def test_icon_memory_profiles_share_character_ids_and_omit_conditions(
    tmp_path: Path,
) -> None:
    folders = Folders(tmp_path / "build", tmp_path / "resources", tmp_path / "source")
    # Old shared atlases must disappear when regenerating resources.
    for profile in ("mip", "amoled"):
        for filename in ("icons.png", "icons.fnt"):
            folders.resources(f"fonts/{profile}/generated", filename).write_text("old")
    generate_fonts(folders, "0123456789")
    source = folders.source("generated", "fonts.mc").read_text()
    assert source.count('const ICON_NONE = "";') == 1
    for profile, style in [("mip", fonts.STYLE_2), ("amoled", fonts.STYLE_3)]:
        low = folders.resources(f"memory/low/generated/fonts/{profile}")
        high = folders.resources(f"memory/high/generated/fonts/{profile}")
        _, _, _, full_comments = parse_typeface_and_style(
            fonts.TYPEFACE_ICONS, style, "icons"
        )
        expected = parse_typeface_and_style(
            fonts.TYPEFACE_ICONS_GENERAL, style, "icons"
        )
        low_comments = expected[3]
        assert low_comments == {
            char: comment
            for char, comment in full_comments.items()
            if comment not in fonts.EXTRA_NAMES
        }
        assert set(low_comments.values()) >= {
            "alarm",
            "dawn",
            "dot full",
            "battery empty",
        }
        assert len(low_comments) == 34
        assert not set(low_comments.values()) & fonts.EXTRA_NAMES
        assert len(full_comments) - len(low_comments) == 57
        assert (low / "icons.fnt").read_text() == expected[2]
        with Image.open(low / "icons.png") as actual, Image.open(
            high / "icons.png"
        ) as full:
            assert actual.tobytes() == expected[1].tobytes()
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
    for comment in fonts.EXTRA_NAMES:
        name = comment.replace(" ", "_").upper()
        assert f"(:memory_not_low)\n\tconst ICON_{name} =" in source
