# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

from data.fonts import TYPEFACE_DOT

RESOURCES_DIR = "resources"


def get_strings_xml_files() -> list[Path]:
    return sorted(Path(RESOURCES_DIR).glob("*/strings.xml"))


def get_string_ids(strings_xml: Path) -> set[str]:
    tree = ET.parse(strings_xml)
    root = tree.getroot()

    return {string.get("id", "") for string in root.findall("string")}


def get_defined_strings(strings_xml: Path, prefix: str) -> set[str]:
    tree = ET.parse(strings_xml)
    root = tree.getroot()

    return {
        string.get("id", "")
        for string in root.findall("string")
        if string.get("id", "").startswith(prefix)
    }


def get_defined_string_entries(strings_xml: Path, prefix: str) -> list[tuple[str, str]]:
    tree = ET.parse(strings_xml)
    root = tree.getroot()

    return [
        (string.get("id", ""), string.text or "")
        for string in root.findall("string")
        if string.get("id", "").startswith(prefix)
    ]


def get_string_entries_with_invalid_length(
    strings_xml: Path,
    prefix: str,
    *,
    exact_length: int | None = None,
    max_length: int | None = None,
) -> list[tuple[str, str, int]]:
    assert exact_length is not None or max_length is not None

    invalid_entries = []

    for string_id, value in get_defined_string_entries(strings_xml, prefix):
        value_length = len(value)

        if exact_length is not None and value_length != exact_length:
            invalid_entries.append((string_id, value, value_length))
        elif max_length is not None and value_length > max_length:
            invalid_entries.append((string_id, value, value_length))

    return sorted(invalid_entries)


def get_resource_characters() -> set[str]:
    characters: set[str] = set()

    for strings_xml in get_strings_xml_files():
        tree = ET.parse(strings_xml)
        for string in tree.getroot().findall("string"):
            characters.update(string.text or "")

    return characters


@pytest.mark.parametrize("strings_xml", get_strings_xml_files(), ids=str)
def test_all_strings_files_define_the_same_string_ids(strings_xml: Path) -> None:
    reference = Path(RESOURCES_DIR) / "base" / "strings.xml"
    expected = get_string_ids(reference)
    actual = get_string_ids(strings_xml)

    missing = sorted(expected - actual)
    extra = sorted(actual - expected)

    assert not missing and not extra, (
        f"String ids in {strings_xml} differ from {reference}:\n"
        + "\n".join(f"  - missing: {string_id}" for string_id in missing)
        + "\n"
        + "\n".join(f"  - extra: {string_id}" for string_id in extra)
    )


@pytest.mark.parametrize(
    "strings_xml", sorted(Path(RESOURCES_DIR).glob("lang/*/strings.xml")), ids=str
)
def test_locales_define_every_setting_string(strings_xml: Path) -> None:
    expected = get_defined_strings(
        Path(RESOURCES_DIR) / "base" / "strings.xml", "SETTING_"
    )
    actual = get_defined_strings(strings_xml, "SETTING_")

    assert actual == expected, (
        f"Setting strings in {strings_xml} differ from base: "
        f"missing={sorted(expected - actual)}, extra={sorted(actual - expected)}"
    )


@pytest.mark.parametrize("strings_xml", get_strings_xml_files(), ids=str)
def test_all_watchface_label_strings_have_max_length_five(strings_xml: Path) -> None:
    too_long = get_string_entries_with_invalid_length(
        strings_xml, "LABEL_", max_length=5
    )

    assert (
        not too_long
    ), f"Watchface LABEL_ strings longer than 5 chars in {strings_xml}:\n" + "\n".join(
        f"  - {string_id}: {length} ({value})" for string_id, value, length in too_long
    )


@pytest.mark.parametrize("strings_xml", get_strings_xml_files(), ids=str)
def test_all_day_of_week_strings_have_exact_length_three(strings_xml: Path) -> None:
    invalid_entries = get_string_entries_with_invalid_length(
        strings_xml, "DAY_OF_WEEK_", exact_length=3
    )

    assert (
        not invalid_entries
    ), f"DAY_OF_WEEK_ strings not exactly 3 chars in {strings_xml}:\n" + "\n".join(
        f"  - {string_id}: {length} ({value})"
        for string_id, value, length in invalid_entries
    )


@pytest.mark.parametrize("strings_xml", get_strings_xml_files(), ids=str)
def test_all_month_strings_have_exact_length_three(strings_xml: Path) -> None:
    invalid_entries = get_string_entries_with_invalid_length(
        strings_xml, "MONTH_", exact_length=3
    )

    assert (
        not invalid_entries
    ), f"MONTH_ strings not exactly 3 chars in {strings_xml}:\n" + "\n".join(
        f"  - {string_id}: {length} ({value})"
        for string_id, value, length in invalid_entries
    )


@pytest.mark.parametrize("strings_xml", get_strings_xml_files(), ids=str)
@pytest.mark.parametrize("prefix", ("DAY_OF_WEEK_", "MONTH_"))
def test_all_date_abbreviations_contain_only_letters(
    strings_xml: Path, prefix: str
) -> None:
    invalid_entries = [
        (string_id, value)
        for string_id, value in get_defined_string_entries(strings_xml, prefix)
        if not value.isalpha()
    ]

    assert not invalid_entries, (
        f"{prefix} abbreviations in {strings_xml} must contain only letters:\n"
        + "\n".join(f"  - {string_id}: {value}" for string_id, value in invalid_entries)
    )


def test_all_resource_characters_are_supported_by_dot_font() -> None:
    supported = {glyph.name for glyph in TYPEFACE_DOT.glyphs}
    missing = sorted(get_resource_characters() - supported)

    assert not missing, "Missing Dot font glyphs:\n" + "\n".join(
        f"  - {character}" for character in missing
    )
