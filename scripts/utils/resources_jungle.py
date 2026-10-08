# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from pathlib import Path

from data.devices import DEVICES, Device, ScreenType
from scripts.utils.manifest import supported_connect_iq_ids

MEMORY_CLASSES = {
    98304: "low",
    114688: "medium",
    131072: "high",
}


def memory_class_for_limit(limit: int) -> str:
    try:
        return MEMORY_CLASSES[limit]
    except KeyError as error:
        raise ValueError(f"Unsupported watch-face memory limit: {limit}") from error


def supported_devices(manifest_xml: Path) -> list[Device]:
    devices_by_id = {
        device.connect_iq_id: device for device in DEVICES if device.connect_iq_id
    }
    devices = []
    for connect_iq_id in supported_connect_iq_ids(manifest_xml):
        try:
            devices.append(devices_by_id[connect_iq_id])
        except KeyError as error:
            raise ValueError(
                f"Supported device is missing from data/devices: {connect_iq_id}"
            ) from error
    return devices


def render_resources_jungle(manifest_xml: Path) -> str:
    lines = [
        "# Generated from the release manifest and data/devices.",
        "# Do not edit by hand.",
        "",
    ]
    excluded_by_class = {
        "low": ("memory_medium", "memory_high", "memory_not_low"),
        "medium": ("memory_low", "memory_high", "memory_not_medium"),
        "high": ("memory_low", "memory_medium", "memory_not_high"),
    }

    for device in supported_devices(manifest_xml):
        memory_class = memory_class_for_limit(device.memory.watch_face)
        excluded_annotations = ";".join(excluded_by_class[memory_class])
        font_profile = "amoled" if device.screen_type == ScreenType.AMOLED else "mip"
        excluded_font_profile = "mip" if font_profile == "amoled" else "amoled"
        if device.supports_touch is None:
            raise ValueError(
                f"Supported device is missing touch capability: {device.connect_iq_id}"
            )
        excluded_input = "input_not_touch" if device.supports_touch else "input_touch"
        qualifier = device.connect_iq_id
        lines.extend(
            [
                f"{qualifier}.resourcePath = ../resources/base/strings.xml;"
                f"../resources/base/generated;../resources/memory/{memory_class};"
                f"../resources/fonts/{font_profile}/generated",
                f"{qualifier}.excludeAnnotations = "
                f"{excluded_annotations};display_{excluded_font_profile};{excluded_input}",
                "",
            ]
        )

    return "\n".join(lines)
