# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>
import xml.etree.ElementTree as ET
from pathlib import Path

from data.devices import (
    DEVICES,
    Device,
    Devices,
    Memory,
    Resolution,
    ScreenShape,
    ScreenType,
)


def test_devices_contains_all_converted_rows() -> None:
    assert isinstance(DEVICES, Devices)
    assert len(DEVICES) == 149
    assert isinstance(DEVICES.all, list)
    assert len(DEVICES.all) == 149


def test_devices_accepts_variadic_items_and_returns_list_slices() -> None:
    devices = Devices(DEVICES[0], DEVICES[1])

    assert devices.all == [DEVICES[0], DEVICES[1]]
    assert devices[:] == [DEVICES[0], DEVICES[1]]
    assert isinstance(devices.mip64, list)
    assert isinstance(devices.resolution_240x240, list)


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
        assert isinstance(device.screen_shape, ScreenShape)
        assert isinstance(device.connect_iq_id, str)
        assert isinstance(device.memory.watch_face, int)


def test_devices_record_watch_face_memory_limit() -> None:
    memory_by_connect_iq_id = {
        device.connect_iq_id: device.memory.watch_face
        for device in DEVICES
        if device.connect_iq_id
    }

    expected_memory_by_connect_iq_id = {
        "descentmk2": 131072,
        "descentmk2s": 98304,
        "descentg1": 65536,
        "epix": 1048576,
        "instinct2": 65536,
        "instinct2s": 65536,
        "instinct2x": 65536,
        "instinct3solar45mm": 65536,
        "instinctcrossover": 65536,
        "instincte40mm": 65536,
        "instincte45mm": 65536,
        "venusq2": 131072,
        "venusq2m": 131072,
        "venux1": 131072,
        "enduro": 114688,
        "enduro3": 131072,
        "enduro4": 131072,
        "fenix6": 114688,
        "fenix6pro": 114688,
        "fenix6s": 98304,
        "fenix6spro": 98304,
        "fenix6xpro": 131072,
        "fenix7": 131072,
        "fenix7pro": 131072,
        "fenix7pronowifi": 131072,
        "fenix7s": 131072,
        "fenix7spro": 131072,
        "fenix7x": 131072,
        "fenix7xpro": 131072,
        "fenix7xpronowifi": 131072,
        "fenix8solar47mm": 131072,
        "fenix8solar51mm": 131072,
        "fr255": 131072,
        "fr255m": 131072,
        "fr945lte": 98304,
        "fr230": 65536,
        "fr235": 65536,
        "fr630": 65536,
        "fr735xt": 65536,
        "fr920xt": 65536,
        "venusq": 98304,
        "venusqm": 524288,
        "vivoactive": 65536,
        "vivoactive_hr": 65536,
        "fr955": 131072,
        "marqadventurer": 98304,
        "marqathlete": 98304,
        "marqaviator": 98304,
        "marqcaptain": 98304,
        "marqcommander": 98304,
        "marqdriver": 98304,
        "marqexpedition": 98304,
        "marqgolfer": 98304,
    }

    assert {
        connect_iq_id: memory_by_connect_iq_id[connect_iq_id]
        for connect_iq_id in expected_memory_by_connect_iq_id
    } == expected_memory_by_connect_iq_id


def test_devices_record_garmin_api_version() -> None:
    api_by_connect_iq_id = {
        device.connect_iq_id: device.api_version
        for device in DEVICES
        if device.connect_iq_id
    }

    assert api_by_connect_iq_id["fenix7"] == "5.2"
    assert api_by_connect_iq_id["fenix9pro51mm"] == "6.0"
    assert api_by_connect_iq_id["fr945lte"] == "3.4"
    assert api_by_connect_iq_id["fr735xt"] == "2.4"


def test_devices_include_older_watch_models() -> None:
    device_ids = {device.connect_iq_id for device in DEVICES}

    assert {
        "epix",
        "fr230",
        "fr235",
        "fr630",
        "fr735xt",
        "fr920xt",
        "venusq",
        "venusqm",
        "vivoactive",
        "vivoactive_hr",
    } <= device_ids


def test_devices_filter_by_screen_type() -> None:
    assert len(DEVICES.mip2) == 8
    assert len(DEVICES.mip8) == 3
    assert len(DEVICES.mip16) == 9
    assert len(DEVICES.mip64) == 70
    assert len(DEVICES.lcd) == 2
    assert len(DEVICES.amoled) == 57
    assert all(device.screen_type == ScreenType.MIP2 for device in DEVICES.mip2)
    assert all(device.screen_type == ScreenType.MIP8 for device in DEVICES.mip8)
    assert all(device.screen_type == ScreenType.MIP16 for device in DEVICES.mip16)
    assert all(device.screen_type == ScreenType.MIP64 for device in DEVICES.mip64)
    assert all(device.screen_type == ScreenType.LCD for device in DEVICES.lcd)
    assert all(device.screen_type == ScreenType.AMOLED for device in DEVICES.amoled)


def test_devices_record_screen_shape() -> None:
    shapes_by_id = {device.connect_iq_id: device.screen_shape for device in DEVICES}

    assert shapes_by_id["instinct2"] == ScreenShape.SEMI_OCTAGON
    assert shapes_by_id["descentg1"] == ScreenShape.SEMI_OCTAGON
    assert shapes_by_id["venusq2"] == ScreenShape.RECTANGLE
    assert shapes_by_id["venux1"] == ScreenShape.RECTANGLE
    assert shapes_by_id["fenix7"] == ScreenShape.ROUND
    assert shapes_by_id["fr735xt"] == ScreenShape.SEMI_ROUND
    assert shapes_by_id["fr920xt"] == ScreenShape.RECTANGLE


def test_devices_expose_known_resolutions() -> None:
    assert DEVICES.resolutions == (
        Resolution(148, 205),
        Resolution(163, 156),
        Resolution(166, 166),
        Resolution(176, 176),
        Resolution(205, 148),
        Resolution(208, 208),
        Resolution(215, 180),
        Resolution(218, 218),
        Resolution(240, 240),
        Resolution(260, 260),
        Resolution(280, 280),
        Resolution(320, 360),
        Resolution(360, 360),
        Resolution(390, 390),
        Resolution(416, 416),
        Resolution(448, 486),
        Resolution(454, 454),
        Resolution(466, 466),
    )
    assert len(DEVICES.resolution_240x240) == 38
    assert len(DEVICES.resolution_260x260) == 14
    assert len(DEVICES.resolution_280x280) == 10
    assert len(DEVICES.resolution_390x390) == 23
    assert len(DEVICES.resolution_416x416) == 13
    assert len(DEVICES.resolution_454x454) == 15


def test_manifest_products_match_supported_connect_iq_ids() -> None:
    namespace = {"iq": "http://www.garmin.com/xml/connectiq"}
    manifest = ET.parse(Path("manifest.xml.tmpl")).getroot()
    products = {
        product.get("id", "")
        for product in manifest.findall(".//iq:products/iq:product", namespace)
    }

    device_ids = {device.connect_iq_id for device in DEVICES if device.connect_iq_id}

    assert products <= device_ids
