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


def test_render_resources_jungle_maps_supported_devices() -> None:
    jungle = render_resources_jungle(Path("manifest.xml.tmpl"))

    assert jungle.count(".resourcePath =") == len(
        supported_devices(Path("manifest.xml.tmpl"))
    )
    assert jungle.count("../resources/memory/low/generated/settings.xml;") == 12
    assert jungle.count("../resources/memory/medium/generated/settings.xml;") == 3
    assert jungle.count("../resources/memory/high/generated/settings.xml;") == sum(
        device.memory.watch_face == 131072
        for device in supported_devices(Path("manifest.xml.tmpl"))
    )
    assert (
        "descentmk2s.resourcePath = ../resources/base/strings.xml;"
        "../resources/base/generated;../resources/memory/low" in jungle
    )
    assert (
        "enduro.excludeAnnotations = "
        "memory_low;memory_high;memory_not_medium" in jungle
    )
    assert (
        "fr955.excludeAnnotations = "
        "memory_low;memory_medium;memory_not_high" in jungle
    )
    assert (
        "descentmk2s.excludeAnnotations = "
        "memory_medium;memory_high;memory_not_low" in jungle
    )


def test_render_resources_jungle_ignores_unsupported_devices() -> None:
    jungle = render_resources_jungle(Path("manifest.xml.tmpl"))

    assert "venu.resourcePath" not in jungle
    assert "fr745" not in jungle


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
    lines = render_resources_jungle(manifest).splitlines()
    for device in supported_devices(manifest):
        profile = "amoled" if device.screen_type == ScreenType.AMOLED else "mip"
        excluded = "mip" if profile == "amoled" else "amoled"
        resources = next(
            line
            for line in lines
            if line.startswith(f"{device.connect_iq_id}.resourcePath =")
        )
        annotations = next(
            line
            for line in lines
            if line.startswith(f"{device.connect_iq_id}.excludeAnnotations =")
        )
        paths = resources.split(" = ", 1)[1].split(";")
        # Select XML files directly so recursive resource discovery cannot
        # include both display variants beneath the memory folder.
        assert (
            f"../resources/memory/{memory_class_for_limit(device.memory.watch_face)}"
            not in paths
        )
        assert resources.count("/fonts/") == 2
        memory = memory_class_for_limit(device.memory.watch_face)
        assert (
            resources.split(" = ", 1)[1]
            .split(";")
            .count(f"../resources/memory/{memory}/generated/fonts/{profile}")
            == 1
        )
        assert resources.endswith(f"/fonts/{profile}/generated")
        assert f"display_{excluded}" in annotations.split(" = ", 1)[1].split(";")
        assert f"display_{profile}" not in annotations


def test_input_profiles_match_every_supported_device() -> None:
    manifest = Path("manifest.xml.tmpl")
    lines = render_resources_jungle(manifest).splitlines()
    for device in supported_devices(manifest):
        annotations = (
            next(
                line
                for line in lines
                if line.startswith(f"{device.connect_iq_id}.excludeAnnotations =")
            )
            .split(" = ", 1)[1]
            .split(";")
        )
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
