# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import json
from pathlib import Path
from typing import TypedDict

from data.devices import DEVICES
from scripts.utils.site_settings import supported_connect_iq_ids


class DeviceMemoryData(TypedDict):
    watchFace: int


class DeviceData(TypedDict):
    connectIqId: str
    productId: str
    supported: bool
    resolution: dict[str, int]
    screenType: str
    memory: DeviceMemoryData
    apiVersion: str


def device_data(manifest_xml: Path = Path("manifest.xml")) -> list[DeviceData]:
    supported_ids = set(supported_connect_iq_ids(manifest_xml))

    return [
        {
            "connectIqId": device.connect_iq_id,
            "productId": device.product_id,
            "supported": device.connect_iq_id in supported_ids,
            "resolution": {
                "height": device.resolution.height,
                "width": device.resolution.width,
            },
            "screenType": device.screen_type.value,
            "memory": {
                "watchFace": device.memory.watch_face,
            },
            "apiVersion": device.api_version,
        }
        for device in DEVICES
    ]


def write_devices_js(
    devices: list[DeviceData],
    output: Path,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(devices, indent=2, sort_keys=True)
    output.write_text(f"window.PHASE_DEVICES = {payload};\n", encoding="utf-8")


def build_site_devices(
    manifest_xml: Path = Path("manifest.xml"),
    output: Path = Path("build/site/devices-data.js"),
) -> None:
    write_devices_js(device_data(manifest_xml), output)
