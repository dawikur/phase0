# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import re
import xml.etree.ElementTree as ET

PROPERTIES_XML = "resources/generated/properties.xml"
SETTINGS_XML = "resources/generated/settings.xml"
PROPERTIES_MC = "source/generated/properties.mc"

SETTINGS_PROPERTY_RE = re.compile(r"@Properties\.([A-Za-z0-9_]+)\b")
MC_PROPERTY_RE = re.compile(r'Application\.Properties\.getValue\("([A-Za-z0-9_]+)"\)')


def get_defined_properties() -> set[str]:
    tree = ET.parse(PROPERTIES_XML)
    root = tree.getroot()

    return {prop.get("id", "") for prop in root.findall("property") if prop.get("id")}


def get_used_in_settings() -> set[str]:
    with open(SETTINGS_XML, encoding="utf-8") as file:
        return set(SETTINGS_PROPERTY_RE.findall(file.read()))


def get_used_in_mc() -> set[str]:
    with open(PROPERTIES_MC, encoding="utf-8") as file:
        return set(MC_PROPERTY_RE.findall(file.read()))


def test_all_properties_are_used() -> None:
    defined = get_defined_properties()

    settings_used = get_used_in_settings()
    mc_used = get_used_in_mc()

    missing_settings = sorted(defined - settings_used)
    missing_mc = sorted(defined - mc_used)

    assert not missing_settings, "Properties missing in settings.xml:\n" + "\n".join(
        f"  - {prop}" for prop in missing_settings
    )

    assert not missing_mc, "Properties missing in properties.mc:\n" + "\n".join(
        f"  - {prop}" for prop in missing_mc
    )
