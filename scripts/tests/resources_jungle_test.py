# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from dataclasses import replace
from pathlib import Path

import pytest

from data.devices import ScreenType
from scripts.utils.resources_jungle import (
    memory_class_for_limit,
    render_resources_jungle,
    supported_devices,
)


def test_memory_class_for_limit_uses_supported_limits() -> None:
    assert memory_class_for_limit(98304) == "low"
    assert memory_class_for_limit(114688) == "medium"
    assert memory_class_for_limit(131072) == "high"


def test_memory_class_for_limit_rejects_unknown_limit() -> None:
    with pytest.raises(ValueError, match="Unsupported watch-face memory limit"):
        memory_class_for_limit(65536)


def jungle_settings(manifest: Path) -> dict[str, list[str]]:
    return {
        key.strip(): value.strip().split(";")
        for line in render_resources_jungle(manifest).splitlines()
        if "=" in line
        for key, value in [line.split("=", 1)]
    }


def test_resources_are_selected_only_for_supported_devices() -> None:
    manifest = Path("manifest.xml.tmpl")
    settings = jungle_settings(manifest)
    assert {
        key.removesuffix(".resourcePath")
        for key in settings
        if key.endswith(".resourcePath")
    } == {device.connect_iq_id for device in supported_devices(manifest)}
    for device in supported_devices(manifest):
        memory = memory_class_for_limit(device.memory.watch_face)
        paths = settings[f"{device.connect_iq_id}.resourcePath"]
        selected = {path for path in paths if path.endswith("/settings.xml")}
        assert selected == {f"../resources/memory/{memory}/generated/settings.xml"}
        excluded = set(settings[f"{device.connect_iq_id}.excludeAnnotations"])
        assert f"memory_{memory}" not in excluded
        assert f"memory_not_{memory}" in excluded
        assert {
            f"memory_{other}" for other in ("low", "medium", "high") if other != memory
        } <= excluded


def test_render_resources_jungle_rejects_unknown_supported_device(
    tmp_path: Path,
) -> None:
    manifest = tmp_path / "manifest.xml"
    manifest.write_text(
        """
        <iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq">
            <iq:products><iq:product id="unknown" /></iq:products>
        </iq:manifest>
        """,
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="missing from data/devices: unknown"):
        render_resources_jungle(manifest)


def test_font_profiles_match_every_supported_device() -> None:
    manifest = Path("manifest.xml.tmpl")
    settings = jungle_settings(manifest)
    for device in supported_devices(manifest):
        profile = "amoled" if device.screen_type == ScreenType.AMOLED else "mip"
        excluded = "mip" if profile == "amoled" else "amoled"
        paths = settings[f"{device.connect_iq_id}.resourcePath"]
        annotations = settings[f"{device.connect_iq_id}.excludeAnnotations"]
        memory = memory_class_for_limit(device.memory.watch_face)
        assert f"../resources/memory/{memory}" not in paths
        assert {path for path in paths if "/fonts/" in path} == {
            f"../resources/memory/{memory}/generated/fonts/{profile}",
            f"../resources/fonts/{profile}/generated",
        }
        assert f"display_{excluded}" in annotations
        assert f"display_{profile}" not in annotations


def test_input_profiles_match_every_supported_device() -> None:
    manifest = Path("manifest.xml.tmpl")
    settings = jungle_settings(manifest)
    for device in supported_devices(manifest):
        annotations = settings[f"{device.connect_iq_id}.excludeAnnotations"]
        excluded = "input_not_touch" if device.supports_touch else "input_touch"
        included = "input_touch" if device.supports_touch else "input_not_touch"
        assert excluded in annotations
        assert included not in annotations


def test_resources_jungle_rejects_unknown_touch_capability(monkeypatch) -> None:
    manifest = Path("manifest.xml.tmpl")
    device = replace(supported_devices(manifest)[0], supports_touch=None)
    monkeypatch.setattr(
        "scripts.utils.resources_jungle.supported_devices", lambda _: [device]
    )
    with pytest.raises(ValueError, match="missing touch capability: approachs50"):
        render_resources_jungle(manifest)
