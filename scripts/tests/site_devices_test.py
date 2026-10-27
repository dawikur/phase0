# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from pathlib import Path

from scripts.tests.javascript_helpers import window_value
from scripts.utils.site_devices import build_site_devices, device_data, write_devices_js
from scripts.utils.site_settings import supported_connect_iq_ids


def test_site_devices_include_device_display_and_memory_data() -> None:
    devices = device_data()
    by_connect_iq_id = {
        device["connectIqId"]: device for device in devices if device["connectIqId"]
    }

    assert len(devices) == 149
    assert by_connect_iq_id["approachs7243mm"]["resolution"] == {
        "height": 416,
        "width": 416,
    }
    assert by_connect_iq_id["approachs7247mm"]["resolution"] == {
        "height": 454,
        "width": 454,
    }
    assert by_connect_iq_id["enduro4"]["screenType"] == "MIP64"
    assert by_connect_iq_id["fenix7"] == {
        "connectIqId": "fenix7",
        "productId": "Fenix 7 / quatix 7",
        "supported": True,
        "resolution": {"height": 260, "width": 260},
        "screenShape": "round",
        "screenType": "MIP64",
        "memory": {"watchFace": 131072},
        "apiVersion": "5.2",
    }
    assert by_connect_iq_id["fenix7spro"]["memory"]["watchFace"] == 131072
    assert by_connect_iq_id["instinct2"]["screenShape"] == "semi-octagon"
    assert by_connect_iq_id["venusq2"]["screenShape"] == "rectangle"
    assert by_connect_iq_id["fr735xt"] == {
        "connectIqId": "fr735xt",
        "productId": "Forerunner 735XT",
        "supported": False,
        "resolution": {"height": 180, "width": 215},
        "screenShape": "semi-round",
        "screenType": "MIP16",
        "memory": {"watchFace": 65536},
        "apiVersion": "2.4",
    }
    assert by_connect_iq_id["fr745"]["supported"] is False
    assert "Forerunner 745" in [device["productId"] for device in devices]
    assert {device["connectIqId"] for device in devices if device["supported"]} == set(
        supported_connect_iq_ids(Path("manifest.xml.tmpl"))
    )


def test_site_devices_writer_exposes_data_on_window(tmp_path: Path) -> None:
    output = tmp_path / "devices-data.js"

    write_devices_js(device_data()[:1], output)

    assert window_value(output, "PHASE_DEVICES") == device_data()[:1]


def test_site_devices_builder_writes_default_data(tmp_path: Path) -> None:
    output = tmp_path / "nested" / "devices-data.js"

    build_site_devices(Path("manifest.xml.tmpl"), output)

    assert output.exists()
    assert window_value(output, "PHASE_DEVICES") == device_data(
        Path("manifest.xml.tmpl")
    )
