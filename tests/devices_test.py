# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>
import xml.etree.ElementTree as ET
from pathlib import Path

from data.devices import DEVICES, Device, Devices, Resolution, ScreenType


def test_devices_contains_all_converted_rows() -> None:
    assert isinstance(DEVICES, Devices)
    assert len(DEVICES) == 80
    assert len(DEVICES.all) == 80


def test_devices_preserve_source_order_and_representative_values() -> None:
    assert DEVICES[0] == Device(
        "Approach S50",
        Resolution(390, 390),
        ScreenType.AMOLED,
        "approachs50",
        api_version="5.1",
    )
    assert (
        Device(
            "Fenix 7X / tactix 7 / quatix 7X / Enduro 2",
            Resolution(280, 280),
            ScreenType.MIP64,
            "fenix7x",
            total_memory=126792,
            api_version="5.2",
        )
        in DEVICES.all
    )
    assert DEVICES[-1] == Device(
        "vívoactive 6",
        Resolution(390, 390),
        ScreenType.AMOLED,
        "vivoactive6",
        api_version="6.0",
    )


def test_devices_use_typed_resolution_and_screen_type() -> None:
    for device in DEVICES:
        assert isinstance(device.resolution.width, int)
        assert isinstance(device.resolution.height, int)
        assert isinstance(device.screen_type, ScreenType)
        assert isinstance(device.connect_iq_id, str)
        assert isinstance(device.total_memory, int)


def test_devices_record_total_memory_when_measured() -> None:
    memory_by_connect_iq_id = {
        device.connect_iq_id: device.total_memory
        for device in DEVICES
        if device.connect_iq_id
    }

    assert memory_by_connect_iq_id["descentmk2"] == 126792
    assert memory_by_connect_iq_id["descentmk2s"] == 94024
    assert memory_by_connect_iq_id["enduro"] == 110408
    assert memory_by_connect_iq_id["enduro3"] == 126792
    assert memory_by_connect_iq_id["fenix6"] == 110408
    assert memory_by_connect_iq_id["fenix6pro"] == 110408
    assert memory_by_connect_iq_id["fenix6s"] == 94024
    assert memory_by_connect_iq_id["fenix6spro"] == 94024
    assert memory_by_connect_iq_id["fenix6xpro"] == 126792
    assert memory_by_connect_iq_id["fenix7"] == 126792
    assert memory_by_connect_iq_id["fenix7pro"] == 126792
    assert memory_by_connect_iq_id["fenix7pronowifi"] == 126792
    assert memory_by_connect_iq_id["fenix7s"] == 126792
    assert memory_by_connect_iq_id["fenix7spro"] == 126792
    assert memory_by_connect_iq_id["fenix7x"] == 126792
    assert memory_by_connect_iq_id["fenix7xpro"] == 126792
    assert memory_by_connect_iq_id["fenix7xpronowifi"] == 126792
    assert memory_by_connect_iq_id["fenix8solar47mm"] == 126792
    assert memory_by_connect_iq_id["fenix8solar51mm"] == 126792
    assert memory_by_connect_iq_id["fr255"] == 126792
    assert memory_by_connect_iq_id["fr255m"] == 126792
    assert memory_by_connect_iq_id["fr945lte"] == 94024
    assert memory_by_connect_iq_id["fr955"] == 126792
    assert memory_by_connect_iq_id["marqadventurer"] == 94024
    assert memory_by_connect_iq_id["marqathlete"] == 94024
    assert memory_by_connect_iq_id["marqaviator"] == 94024
    assert memory_by_connect_iq_id["marqcaptain"] == 94024
    assert memory_by_connect_iq_id["marqcommander"] == 94024
    assert memory_by_connect_iq_id["marqdriver"] == 94024
    assert memory_by_connect_iq_id["marqexpedition"] == 94024
    assert memory_by_connect_iq_id["marqgolfer"] == 94024


def test_devices_record_garmin_api_version() -> None:
    api_by_connect_iq_id = {
        device.connect_iq_id: device.api_version
        for device in DEVICES
        if device.connect_iq_id
    }

    assert api_by_connect_iq_id["fenix7"] == "5.2"
    assert api_by_connect_iq_id["fenix9pro51mm"] == "6.0"
    assert api_by_connect_iq_id["fr945lte"] == "3.4"


def test_devices_filter_by_screen_type() -> None:
    assert len(DEVICES.mip64) == 35
    assert len(DEVICES.amoled) == 45
    assert all(device.screen_type == ScreenType.MIP64 for device in DEVICES.mip64)
    assert all(device.screen_type == ScreenType.AMOLED for device in DEVICES.amoled)


def test_devices_expose_known_resolutions() -> None:
    assert DEVICES.resolutions == (
        Resolution(218, 218),
        Resolution(240, 240),
        Resolution(260, 260),
        Resolution(280, 280),
        Resolution(360, 360),
        Resolution(390, 390),
        Resolution(416, 416),
        Resolution(454, 454),
        Resolution(466, 466),
    )
    assert len(DEVICES.resolution_240x240) == 14
    assert len(DEVICES.resolution_260x260) == 10
    assert len(DEVICES.resolution_280x280) == 9
    assert len(DEVICES.resolution_390x390) == 16
    assert len(DEVICES.resolution_416x416) == 12
    assert len(DEVICES.resolution_454x454) == 14


def test_manifest_products_match_supported_connect_iq_ids() -> None:
    namespace = {"iq": "http://www.garmin.com/xml/connectiq"}
    manifest = ET.parse(Path("manifest.xml")).getroot()
    products = {
        product.get("id", "")
        for product in manifest.findall(".//iq:products/iq:product", namespace)
    }

    supported = {
        device.connect_iq_id for device in DEVICES.mip64 if device.connect_iq_id
    }

    assert products == supported
