# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import xml.etree.ElementTree as ET
from pathlib import Path

from scripts.utils.icon_generation import render_svg, render_xml, rgba_to_svg


def test_rgba_to_svg_uses_rgb_for_opaque_colors() -> None:
    assert rgba_to_svg((1, 2, 3, 255)) == "rgb(1,2,3)"


def test_rgba_to_svg_uses_rgba_for_transparent_colors() -> None:
    assert rgba_to_svg((1, 2, 3, 128)) == "rgba(1,2,3,0.5019607843137255)"


def test_render_svg_contains_svg_rectangles() -> None:
    svg = render_svg()

    root = ET.fromstring(svg)
    assert root.tag == "{http://www.w3.org/2000/svg}svg"
    rectangles = root.findall("{http://www.w3.org/2000/svg}rect")
    assert rectangles
    assert any(rect.get("fill") == "rgb(255,170,0)" for rect in rectangles)


def test_render_xml_references_generated_icon() -> None:
    xml = render_xml(Path("resources/base/generated/icon.svg"))

    root = ET.fromstring(xml)
    bitmap = root.find(".//bitmap")
    assert bitmap is not None
    assert bitmap.attrib == {"id": "ICON", "filename": "icon.svg", "dithering": "none"}
