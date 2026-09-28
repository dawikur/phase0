# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from data.devices import DEVICES

STRING_REF_RE = re.compile(r"^@Strings\.([A-Za-z0-9_]+)$")
PROPERTY_REF_RE = re.compile(r"^@Properties\.([A-Za-z0-9_]+)$")
REPEATED_GROUP_RE = re.compile(
    r"^(Status|Gauges|TopMiddle|BottomMiddle)(?:Alt|Alternative)?\d+$"
)
CONNECT_IQ_NAMESPACE = {"iq": "http://www.garmin.com/xml/connectiq"}
LANGUAGE_NAMES = {
    "deu": "German",
    "eng": "English",
    "fre": "French",
    "ita": "Italian",
    "pol": "Polish",
    "por": "Portuguese",
    "spa": "Spanish",
}


def load_strings(resources_dir: Path) -> dict[str, str]:
    strings: dict[str, str] = {}
    strings_xml = resources_dir / "base" / "strings.xml"

    root = ET.parse(strings_xml).getroot()
    for string in root.findall("string"):
        string_id = string.get("id")
        if string_id:
            strings[string_id] = string.text or string_id

    return strings


def resolve_text(value: str | None, strings: dict[str, str]) -> str:
    if not value:
        return ""

    match = STRING_REF_RE.match(value)
    if match:
        return strings.get(match.group(1), match.group(1).replace("_", " ").title())

    return value


def resolve_property(value: str | None) -> str:
    if not value:
        return ""

    match = PROPERTY_REF_RE.match(value)
    if match:
        return match.group(1)

    return value


def setting_region(group_id: str) -> str:
    group_id = display_group_id(group_id)

    exact_regions = {
        "General": "theme",
        "Clock": "clock",
        "TopOuter": "top_outer",
        "BottomOuter": "bottom_outer",
    }
    if group_id in exact_regions:
        return exact_regions[group_id]

    prefix_regions = {
        "Status": "status",
        "Gauges": "gauges",
        "TopMiddle": "top",
        "BottomMiddle": "bottom",
    }
    for prefix, region in prefix_regions.items():
        if group_id.startswith(prefix):
            return region

    return "other"


def display_group_id(group_id: str) -> str:
    match = REPEATED_GROUP_RE.match(group_id)
    return match.group(1) if match else group_id


def is_alternative_group(source_group_id: str) -> bool:
    return bool(re.search(r"(?:Alt|Alternative)\d+$", source_group_id))


def setting_summary(group_id: str) -> str:
    summaries = {
        "General": "Global palette controls for the whole watch face.",
        "Clock": "Main time display colors and size.",
        "theme": "Global palette controls for the whole watch face.",
        "clock": "Main time display colors and size.",
        "status": "Small system indicators shown near the clock.",
        "gauges": "Side gauge widgets for progress-style metrics.",
        "top": "Upper middle slots for weather and compact metrics.",
        "top_outer": "Top outer slot for battery or sun and moon widgets.",
        "bottom": "Lower metrics for health and activity data.",
        "bottom_outer": "Bottom outer slot for battery or sun and moon widgets.",
    }

    return summaries.get(
        group_id,
        summaries.get(setting_region(group_id), "Configurable watch face area."),
    )


def supported_connect_iq_ids(manifest_xml: Path) -> list[str]:
    root = ET.parse(manifest_xml).getroot()
    return [
        product.get("id", "")
        for product in root.findall(".//iq:products/iq:product", CONNECT_IQ_NAMESPACE)
        if product.get("id")
    ]


def supported_devices(manifest_xml: Path) -> list[str]:
    products = supported_connect_iq_ids(manifest_xml)
    by_connect_iq_id = {
        device.connect_iq_id: device.product_id
        for device in DEVICES
        if device.connect_iq_id
    }

    return [by_connect_iq_id.get(product_id, product_id) for product_id in products]


def supported_languages(manifest_xml: Path) -> list[dict[str, str]]:
    root = ET.parse(manifest_xml).getroot()
    languages = []

    for language in root.findall(".//iq:languages/iq:language", CONNECT_IQ_NAMESPACE):
        code = (language.text or "").strip()
        if not code:
            continue

        languages.append(
            {
                "code": code,
                "name": LANGUAGE_NAMES.get(code, code.upper()),
            }
        )

    return languages


def parse_settings(
    settings_xml: Path,
    resources_dir: Path,
    manifest_xml: Path = Path("manifest.xml"),
) -> dict[str, Any]:
    strings = load_strings(resources_dir)
    root = ET.parse(settings_xml).getroot()
    groups = []
    seen_group_ids: set[str] = set()
    alternative_groups = {
        display_group_id(group.get("id", ""))
        for group in root.findall("group")
        if is_alternative_group(group.get("id", ""))
    }

    for group in root.findall("group"):
        source_group_id = group.get("id", "")
        group_id = display_group_id(source_group_id)

        if group_id in seen_group_ids:
            continue

        seen_group_ids.add(group_id)
        parsed_group: dict[str, Any] = {
            "id": group_id,
            "sourceId": source_group_id,
            "hasAlternative": group_id in alternative_groups,
            "title": resolve_text(group.get("title"), strings),
            "region": setting_region(group_id),
            "summary": setting_summary(group_id),
            "settings": [],
        }

        for setting in group.findall("setting"):
            config = setting.find("settingConfig")
            parsed_setting: dict[str, Any] = {
                "key": resolve_property(setting.get("propertyKey")),
                "title": resolve_text(setting.get("title"), strings),
                "type": config.get("type", "") if config is not None else "",
                "required": (
                    config.get("required") == "true" if config is not None else False
                ),
                "options": [],
            }

            if config is not None:
                if "min" in config.attrib:
                    parsed_setting["min"] = config.get("min")
                if "max" in config.attrib:
                    parsed_setting["max"] = config.get("max")

                if parsed_setting["type"] == "list":
                    parsed_setting["options"] = [
                        {
                            "value": entry.get("value", ""),
                            "label": resolve_text(entry.text, strings),
                        }
                        for entry in config.findall("listEntry")
                    ]

            parsed_group["settings"].append(parsed_setting)

        groups.append(parsed_group)

    return {
        "source": str(settings_xml),
        "supportedDevices": supported_devices(manifest_xml),
        "supportedLanguages": supported_languages(manifest_xml),
        "groups": groups,
    }


def write_settings_js(data: dict[str, Any], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(data, indent=2, sort_keys=True)
    output.write_text(f"window.PHASE_SETTINGS = {payload};\n", encoding="utf-8")


def build_site_settings(
    resources_dir: Path = Path("resources"),
    settings_xml: Path = Path("resources/memory/high/generated/settings.xml"),
    manifest_xml: Path = Path("manifest.xml"),
    output: Path = Path("build/site/settings-data.js"),
) -> None:
    write_settings_js(parse_settings(settings_xml, resources_dir, manifest_xml), output)
