# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from pathlib import Path

from data.devices import DEVICES, Device
from scripts.utils.site_settings import supported_connect_iq_ids

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


def render_memory_jungle(manifest_xml: Path) -> str:
    lines = [
        "# Generated from manifest.xml and data/devices.",
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
        qualifier = device.connect_iq_id
        lines.extend(
            [
                f"{qualifier}.resourcePath = ../resources/base/strings.xml;"
                f"../resources/base/generated;../resources/memory/{memory_class}",
                f"{qualifier}.excludeAnnotations = $({qualifier}.excludeAnnotations);"
                f"{excluded_annotations}",
                "",
            ]
        )

    return "\n".join(lines)
