# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import xml.etree.ElementTree as ET

from scripts.utils.mc_document import McDocument, McScope
from scripts.utils.xml_document import XmlDocument


def test_mc_document_supports_raw_lines_and_scoped_suffixes() -> None:
    document = McDocument([])
    document.raw("one\ntwo")
    document.line()
    with McScope(document, "function sample(", ";"):
        document.line("value as Lang.Number")

    assert (
        document.render()
        == "one\ntwo\n\nfunction sample(\n\tvalue as Lang.Number\n); // function sample\n"
    )


def test_xml_document_renders_children_with_spacing_and_without_comments() -> None:
    document = XmlDocument.create(ET.Element("root"), comments=())
    document.subelement(document.root, "first", value="1")
    document.subelement(document.root, "second", value="2")

    rendered = document.render(blank_lines_between_root_children=True)

    assert (
        rendered == '<root>\n\t<first value="1" />\n\n\t<second value="2" />\n\n</root>'
    )


def test_xml_document_uses_explicit_comments_and_element_helper() -> None:
    element = XmlDocument.element("item", value="1")
    document = XmlDocument.create(element, comments=None)

    assert document.render(comments=[], blank_line_after_comments=False) == (
        '<item value="1" />'
    )
