# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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
