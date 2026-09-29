# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>
import xml.etree.ElementTree as ET
from pathlib import Path

from data.devices import DEVICES, Device, Devices, Memory, Resolution, ScreenType


def test_devices_contains_all_converted_rows() -> None:
    assert isinstance(DEVICES, Devices)
    assert len(DEVICES) == 125
    assert len(DEVICES.all) == 125


def test_devices_preserve_source_order_and_representative_values() -> None:
    assert DEVICES[0] == Device(
        "Approach S50",
        Resolution(390, 390),
        ScreenType.AMOLED,
        "approachs50",
        memory=Memory(watch_face=131072),
        api_version="5.1",
    )
    assert (
        Device(
            "Fenix 7X / tactix 7 / quatix 7X / Enduro 2",
            Resolution(280, 280),
            ScreenType.MIP64,
            "fenix7x",
            memory=Memory(watch_face=131072),
            api_version="5.2",
        )
        in DEVICES.all
    )
    assert DEVICES[-1] == Device(
        "vívoactive 6",
        Resolution(390, 390),
        ScreenType.AMOLED,
        "vivoactive6",
        memory=Memory(watch_face=131072),
        api_version="6.0",
    )


def test_devices_use_typed_resolution_and_screen_type() -> None:
    for device in DEVICES:
        assert isinstance(device.resolution.width, int)
        assert isinstance(device.resolution.height, int)
        assert isinstance(device.screen_type, ScreenType)
        assert isinstance(device.connect_iq_id, str)
        assert isinstance(device.memory.watch_face, int)


def test_devices_record_watch_face_memory_limit() -> None:
    memory_by_connect_iq_id = {
        device.connect_iq_id: device.memory.watch_face
        for device in DEVICES
        if device.connect_iq_id
    }

    assert memory_by_connect_iq_id["descentmk2"] == 131072
    assert memory_by_connect_iq_id["descentmk2s"] == 98304
    assert memory_by_connect_iq_id["enduro"] == 114688
    assert memory_by_connect_iq_id["enduro3"] == 131072
    assert memory_by_connect_iq_id["fenix6"] == 114688
    assert memory_by_connect_iq_id["fenix6pro"] == 114688
    assert memory_by_connect_iq_id["fenix6s"] == 98304
    assert memory_by_connect_iq_id["fenix6spro"] == 98304
    assert memory_by_connect_iq_id["fenix6xpro"] == 131072
    assert memory_by_connect_iq_id["fenix7"] == 131072
    assert memory_by_connect_iq_id["fenix7pro"] == 131072
    assert memory_by_connect_iq_id["fenix7pronowifi"] == 131072
    assert memory_by_connect_iq_id["fenix7s"] == 131072
    assert memory_by_connect_iq_id["fenix7spro"] == 131072
    assert memory_by_connect_iq_id["fenix7x"] == 131072
    assert memory_by_connect_iq_id["fenix7xpro"] == 131072
    assert memory_by_connect_iq_id["fenix7xpronowifi"] == 131072
    assert memory_by_connect_iq_id["fenix8solar47mm"] == 131072
    assert memory_by_connect_iq_id["fenix8solar51mm"] == 131072
    assert memory_by_connect_iq_id["fr255"] == 131072
    assert memory_by_connect_iq_id["fr255m"] == 131072
    assert memory_by_connect_iq_id["fr945lte"] == 98304
    assert memory_by_connect_iq_id["fr955"] == 131072
    assert memory_by_connect_iq_id["marqadventurer"] == 98304
    assert memory_by_connect_iq_id["marqathlete"] == 98304
    assert memory_by_connect_iq_id["marqaviator"] == 98304
    assert memory_by_connect_iq_id["marqcaptain"] == 98304
    assert memory_by_connect_iq_id["marqcommander"] == 98304
    assert memory_by_connect_iq_id["marqdriver"] == 98304
    assert memory_by_connect_iq_id["marqexpedition"] == 98304
    assert memory_by_connect_iq_id["marqgolfer"] == 98304


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
    assert len(DEVICES.mip64) == 73
    assert len(DEVICES.amoled) == 52
    assert all(device.screen_type == ScreenType.MIP64 for device in DEVICES.mip64)
    assert all(device.screen_type == ScreenType.AMOLED for device in DEVICES.amoled)


def test_devices_expose_known_resolutions() -> None:
    assert DEVICES.resolutions == (
        Resolution(208, 208),
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
    assert len(DEVICES.resolution_240x240) == 36
    assert len(DEVICES.resolution_260x260) == 14
    assert len(DEVICES.resolution_280x280) == 9
    assert len(DEVICES.resolution_390x390) == 23
    assert len(DEVICES.resolution_416x416) == 12
    assert len(DEVICES.resolution_454x454) == 14


def test_manifest_products_match_supported_connect_iq_ids() -> None:
    namespace = {"iq": "http://www.garmin.com/xml/connectiq"}
    manifest = ET.parse(Path("manifest.xml.tmpl")).getroot()
    products = {
        product.get("id", "")
        for product in manifest.findall(".//iq:products/iq:product", namespace)
    }

    device_ids = {device.connect_iq_id for device in DEVICES if device.connect_iq_id}

    assert products <= device_ids
