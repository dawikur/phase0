# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from pathlib import Path

from scripts.utils.site_devices import device_data, write_devices_js
from scripts.utils.site_settings import supported_connect_iq_ids


def test_site_devices_include_device_display_and_memory_data() -> None:
    devices = device_data()
    by_connect_iq_id = {
        device["connectIqId"]: device for device in devices if device["connectIqId"]
    }

    assert len(devices) == 125
    assert by_connect_iq_id["fenix7"] == {
        "connectIqId": "fenix7",
        "productId": "Fenix 7 / quatix 7",
        "supported": True,
        "resolution": {"height": 260, "width": 260},
        "screenType": "MIP64",
        "memory": {"watchFace": 131072},
        "apiVersion": "5.2",
    }
    assert by_connect_iq_id["fenix7spro"]["memory"]["watchFace"] == 131072
    assert by_connect_iq_id["fr745"]["supported"] is False
    assert "Forerunner 745" in [device["productId"] for device in devices]
    assert {device["connectIqId"] for device in devices if device["supported"]} == set(
        supported_connect_iq_ids(Path("manifest.xml"))
    )


def test_site_devices_writer_exposes_data_on_window(tmp_path: Path) -> None:
    output = tmp_path / "devices-data.js"

    write_devices_js(device_data()[:1], output)

    assert output.read_text(encoding="utf-8").startswith("window.PHASE_DEVICES = [")
