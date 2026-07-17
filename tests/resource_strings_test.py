# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>
import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

SOURCE_DIR = "source"
RESOURCES_DIR = "resources"

MC_LABEL_RE = re.compile(r"\bRez\.Strings\.(LABEL_[A-Za-z0-9_]+)\b")
RESOURCES_LABEL_RE = re.compile(r"@Strings\.(LABEL_[A-Za-z0-9_]+)\b")
RESOURCES_SET_RE = re.compile(r"@Strings\.(SET_[A-Za-z0-9_]+)\b")


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


def get_all_defined_strings(prefix: str) -> set[str]:
    defined = set()

    for strings_xml in get_strings_xml_files():
        defined.update(get_defined_strings(strings_xml, prefix))

    return defined


def get_used_mc_labels() -> set[str]:
    used = set()

    for root, _, files in os.walk(SOURCE_DIR):
        for filename in files:
            if filename.endswith(".mc"):
                path = os.path.join(root, filename)
                with open(path, encoding="utf-8") as file:
                    used.update(MC_LABEL_RE.findall(file.read()))

    return used


def get_used_resource_strings(pattern: re.Pattern[str]) -> set[str]:
    used = set()

    for root, _, files in os.walk(RESOURCES_DIR):
        for filename in files:
            if filename.endswith(".xml"):
                path = os.path.join(root, filename)
                with open(path, encoding="utf-8") as file:
                    used.update(pattern.findall(file.read()))

    return used


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


@pytest.mark.parametrize("strings_xml", get_strings_xml_files(), ids=str)
def test_all_watchface_label_strings_are_used_by_monkey_c(strings_xml: Path) -> None:
    defined = get_defined_strings(strings_xml, "LABEL_")
    used = get_used_mc_labels()

    unused = sorted(defined - used)

    assert (
        not unused
    ), f"Unused watchface LABEL_ strings in {strings_xml}:\n" + "\n".join(
        f"  - {label}" for label in unused
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


def test_all_referenced_watchface_label_strings_are_defined() -> None:
    used = get_used_mc_labels()
    defined = get_all_defined_strings("LABEL_")

    undefined = sorted(used - defined)

    assert (
        not undefined
    ), "Undefined watchface LABEL_ strings referenced:\n" + "\n".join(
        f"  - {label}" for label in undefined
    )


@pytest.mark.parametrize("strings_xml", get_strings_xml_files(), ids=str)
def test_all_settings_strings_are_used_by_resources(strings_xml: Path) -> None:
    defined = get_defined_strings(strings_xml, "SET_")
    used = get_used_resource_strings(RESOURCES_SET_RE)

    unused = sorted(defined - used)

    assert not unused, f"Unused settings SET_ strings in {strings_xml}:\n" + "\n".join(
        f"  - {label}" for label in unused
    )


def test_all_referenced_settings_strings_are_defined() -> None:
    used = get_used_resource_strings(RESOURCES_SET_RE)
    defined = get_all_defined_strings("SET_")

    undefined = sorted(used - defined)

    assert not undefined, "Undefined settings SET_ strings referenced:\n" + "\n".join(
        f"  - {label}" for label in undefined
    )


def test_settings_xml_does_not_use_watchface_labels() -> None:
    used = get_used_resource_strings(RESOURCES_LABEL_RE)

    assert (
        not used
    ), "Watchface LABEL_ strings referenced from resources:\n" + "\n".join(
        f"  - {label}" for label in sorted(used)
    )
