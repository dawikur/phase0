# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>
import xml.etree.ElementTree as ET
from pathlib import Path

from data.devices import DEVICES, Device, Devices, Resolution, ScreenType


def test_devices_contains_all_converted_rows() -> None:
    assert isinstance(DEVICES, Devices)
    assert len(DEVICES) == 62
    assert len(DEVICES.all) == 62


def test_devices_preserve_source_order_and_representative_values() -> None:
    assert DEVICES[0] == Device(
        "Forerunner 745",
        Resolution(240, 240),
        ScreenType.MIP,
    )
    assert (
        Device(
            "Fenix 7X / tactix 7 / quatix 7X / Enduro 2",
            Resolution(280, 280),
            ScreenType.MIP,
            ("fenix7x",),
        )
        in DEVICES.all
    )
    assert DEVICES[-1] == Device(
        "Venu 4 45mm",
        Resolution(454, 454),
        ScreenType.AMOLED,
    )


def test_devices_use_typed_resolution_and_screen_type() -> None:
    for device in DEVICES:
        assert isinstance(device.resolution.width, int)
        assert isinstance(device.resolution.height, int)
        assert isinstance(device.screen_type, ScreenType)
        assert isinstance(device.connect_iq_ids, tuple)


def test_devices_filter_by_screen_type() -> None:
    assert len(DEVICES.mip) == 32
    assert len(DEVICES.amoled) == 30
    assert all(device.screen_type == ScreenType.MIP for device in DEVICES.mip)
    assert all(device.screen_type == ScreenType.AMOLED for device in DEVICES.amoled)


def test_devices_expose_known_resolutions() -> None:
    assert DEVICES.resolutions == (
        Resolution(240, 240),
        Resolution(260, 260),
        Resolution(280, 280),
        Resolution(390, 390),
        Resolution(416, 416),
        Resolution(454, 454),
    )
    assert len(DEVICES.resolution_240x240) == 15
    assert len(DEVICES.resolution_260x260) == 9
    assert len(DEVICES.resolution_280x280) == 8
    assert len(DEVICES.resolution_390x390) == 11
    assert len(DEVICES.resolution_416x416) == 9
    assert len(DEVICES.resolution_454x454) == 10


def test_manifest_products_match_supported_connect_iq_ids() -> None:
    namespace = {"iq": "http://www.garmin.com/xml/connectiq"}
    manifest = ET.parse(Path("manifest.xml")).getroot()
    products = {
        product.get("id", "")
        for product in manifest.findall(".//iq:products/iq:product", namespace)
    }

    supported = {
        connect_iq_id
        for device in DEVICES.mip
        for connect_iq_id in device.connect_iq_ids
    }

    assert products == supported
