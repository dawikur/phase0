# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from pathlib import Path

from scripts.utils.icon_generation import render_svg, render_xml, rgba_to_svg


def test_rgba_to_svg_uses_rgb_for_opaque_colors() -> None:
    assert rgba_to_svg((1, 2, 3, 255)) == "rgb(1,2,3)"


def test_rgba_to_svg_uses_rgba_for_transparent_colors() -> None:
    assert rgba_to_svg((1, 2, 3, 128)) == "rgba(1,2,3,0.5019607843137255)"


def test_render_svg_contains_svg_rectangles() -> None:
    svg = render_svg()

    assert svg.startswith("<svg ")
    assert "<rect " in svg
    assert 'fill="rgb(255,170,0)"' in svg


def test_render_xml_references_generated_icon() -> None:
    xml = render_xml(Path("resources/generated/icon.svg"))

    assert '<bitmap id="ICON"' in xml
    assert 'filename="../../resources/generated/icon.svg"' in xml
    assert 'dithering="none"' in xml
