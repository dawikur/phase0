#!/usr/bin/env python3
# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from pathlib import Path

from data import fonts
from scripts.utils.xml_document import XmlDocument

ICON = fonts.ICON
ICON_BLURRED = ICON.blure()


def rgba_to_svg(color: tuple[int, int, int, int]) -> str:
    r, g, b, a = color
    if a == 255:
        return f"rgb({r},{g},{b})"
    return f"rgba({r},{g},{b},{a / 255})"


def render_svg() -> str:
    svg_width = ICON_BLURRED.xadvance * fonts.STYLE_REGULAR.size + 1
    svg_height = ICON_BLURRED.yadvance * fonts.STYLE_REGULAR.size + 1

    svg = XmlDocument.svg(svg_width, svg_height)

    for icon, style, color in [  # pylint: disable=too-many-nested-blocks
        (ICON, fonts.STYLE_REGULAR, (0xAA, 0x55, 0x00, 0xFF)),
        (ICON_BLURRED, fonts.STYLE_REGULAR_THIN, (0xAA, 0x55, 0x00, 0xFF)),
        (ICON, fonts.STYLE_REGULAR_THIN, (0xFF, 0xAA, 0x00, 0xFF)),
    ]:
        fill = rgba_to_svg(color)

        for y in range(icon.yadvance):
            for x in range(icon.xadvance):
                if icon.pixel(x, y):
                    for dy in range(style.weight):
                        for dx in range(style.weight):
                            px = x * style.size + dx
                            py = y * style.size + dy
                            svg.subelement(
                                svg.root,
                                "rect",
                                x=str(px),
                                y=str(py),
                                width="1",
                                height="1",
                                fill=fill,
                            )

    return svg.render(blank_line_after_comments=False)


def render_xml(icon_svg: Path) -> str:
    root = XmlDocument.resource("drawables")
    root.subelement(
        root.root,
        "bitmap",
        id="ICON",
        filename=icon_svg.name,
        dithering="none",
    )
    return root.render()
