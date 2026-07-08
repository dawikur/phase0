# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import os
import re
import xml.etree.ElementTree as ET

STRINGS_XML = "resources/base/strings.xml"
SOURCE_DIR = "source"
RESOURCES_DIR = "resources"

MC_LABEL_RE = re.compile(r"\bRez\.Strings\.(LABEL_[A-Za-z0-9_]+)\b")
RESOURCES_LABEL_RE = re.compile(r"@Strings\.(LABEL_[A-Za-z0-9_]+)\b")


def get_defined_labels() -> set[str]:
    tree = ET.parse(STRINGS_XML)
    root = tree.getroot()

    return {
        string.get("id", "")
        for string in root.findall("string")
        if string.get("id", "").startswith("LABEL_")
    }


def get_used_labels() -> set[str]:
    used = set()

    # Search Monkey C files
    for root, _, files in os.walk(SOURCE_DIR):
        for filename in files:
            if filename.endswith(".mc"):
                path = os.path.join(root, filename)
                with open(path, encoding="utf-8") as file:
                    used.update(MC_LABEL_RE.findall(file.read()))

    # Search generated settings.xml
    for root, _, files in os.walk(RESOURCES_DIR):
        for filename in files:
            if filename.endswith(".xml"):
                path = os.path.join(root, filename)
                with open(path, encoding="utf-8") as file:
                    used.update(RESOURCES_LABEL_RE.findall(file.read()))

    return used


def test_all_label_strings_are_used() -> None:
    defined = get_defined_labels()
    used = get_used_labels()

    unused = sorted(defined - used)
    undefined = sorted(used - defined)

    assert not unused, "Unused LABEL_ strings:\n" + "\n".join(
        f"  - {label}" for label in unused
    )

    assert not undefined, "Undefined LABEL_ strings referenced:\n" + "\n".join(
        f"  - {label}" for label in undefined
    )
