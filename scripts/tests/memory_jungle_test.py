# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from pathlib import Path

import pytest

from scripts.utils.memory_jungle import memory_class_for_limit, render_memory_jungle


def test_memory_class_for_limit_uses_supported_limits() -> None:
    assert memory_class_for_limit(98304) == "low"
    assert memory_class_for_limit(114688) == "medium"
    assert memory_class_for_limit(131072) == "high"


def test_memory_class_for_limit_rejects_unknown_limit() -> None:
    with pytest.raises(ValueError, match="Unsupported watch-face memory limit"):
        memory_class_for_limit(65536)


def test_render_memory_jungle_maps_supported_devices() -> None:
    jungle = render_memory_jungle(Path("manifest.xml"))

    assert jungle.count(".resourcePath =") == 35
    assert jungle.count("../resources/memory/low") == 12
    assert jungle.count("../resources/memory/medium") == 3
    assert jungle.count("../resources/memory/high") == 20
    assert (
        "descentmk2s.resourcePath = ../resources/base/strings.xml;"
        "../resources/base/generated;../resources/memory/low" in jungle
    )
    assert (
        "enduro.excludeAnnotations = $(enduro.excludeAnnotations);"
        "memory_low;memory_high;memory_not_medium" in jungle
    )
    assert (
        "fr955.excludeAnnotations = $(fr955.excludeAnnotations);"
        "memory_low;memory_medium;memory_not_high" in jungle
    )
    assert (
        "descentmk2s.excludeAnnotations = $(descentmk2s.excludeAnnotations);"
        "memory_medium;memory_high;memory_not_low" in jungle
    )


def test_render_memory_jungle_ignores_unsupported_devices() -> None:
    jungle = render_memory_jungle(Path("manifest.xml"))

    assert "approachs50" not in jungle
    assert "fr745" not in jungle


def test_render_memory_jungle_rejects_unknown_supported_device(tmp_path: Path) -> None:
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
        render_memory_jungle(manifest)
