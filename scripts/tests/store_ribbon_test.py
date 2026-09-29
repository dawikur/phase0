# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import runpy
import sys
from pathlib import Path

import pytest
from PIL import Image

from scripts.utils.store_ribbon import add_ribbon


@pytest.mark.parametrize(
    ("channel", "color"), (("alpha", "8951D0"), ("beta", "007E8A"))
)
def test_ribbon_labels_store_artwork(channel: str, color: str) -> None:
    original = Image.new("RGB", (128, 128), "#202020")
    labeled = add_ribbon(original, channel)

    assert original.getpixel((100, 25)) == (32, 32, 32)
    assert labeled.getpixel((100, 25)) != original.getpixel((100, 25))
    assert labeled.getpixel((0, 0)) == original.getpixel((0, 0))
    assert tuple(bytes.fromhex(color)) in labeled.get_flattened_data()
    assert (255, 255, 255) in labeled.crop((64, 0, 128, 64)).get_flattened_data()


def test_ribbon_rejects_non_store_channel() -> None:
    with pytest.raises(ValueError, match="No Store ribbon"):
        add_ribbon(Image.new("RGB", (128, 128)), "developer")


def test_ribbon_cli_writes_labeled_png(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    source = tmp_path / "source.png"
    output = tmp_path / "nested" / "beta.png"
    Image.new("RGB", (128, 128), "#202020").save(source)
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "store_ribbon",
            "--input",
            str(source),
            "--output",
            str(output),
            "--channel",
            "beta",
        ],
    )

    runpy.run_path("scripts/utils/store_ribbon.py", run_name="__main__")

    with Image.open(output) as labeled:
        assert labeled.format == "PNG"
        assert labeled.mode == "RGB"
        assert labeled.getpixel((100, 25)) != (32, 32, 32)
        assert labeled.getpixel((0, 0)) == (32, 32, 32)
