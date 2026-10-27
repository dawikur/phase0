# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import xml.etree.ElementTree as ET


def test_settings_reference_exactly_the_available_properties() -> None:
    properties = ET.parse("resources/memory/high/generated/properties.xml").getroot()
    settings = ET.parse("resources/memory/high/generated/settings.xml").getroot()

    defined = {item.get("id") for item in properties.findall("property")}
    referenced = {
        item.attrib["propertyKey"].removeprefix("@Properties.")
        for item in settings.findall(".//setting")
    }
    assert referenced == defined
