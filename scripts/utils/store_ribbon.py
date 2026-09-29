# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Draw a channel label over Connect IQ Store artwork."""

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

COLORS = {"alpha": "#8951D0", "beta": "#007E8A"}


def add_ribbon(image: Image.Image, channel: str) -> Image.Image:
    if channel not in COLORS:
        raise ValueError(f"No Store ribbon for channel: {channel}")

    width, height = image.size
    unit = min(width, height)
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.polygon(
        [
            (width - round(unit * 0.46), 0),
            (width - round(unit * 0.27), 0),
            (width, round(unit * 0.27)),
            (width, round(unit * 0.46)),
        ],
        fill=COLORS[channel],
    )

    font = ImageFont.load_default(size=max(11, round(unit * 0.105)))
    label = channel.upper()
    bounds = draw.textbbox((0, 0), label, font=font)
    text_width = round(bounds[2] - bounds[0])
    text_height = round(bounds[3] - bounds[1])
    text = Image.new("RGBA", (text_width + 8, text_height + 8), (0, 0, 0, 0))
    ImageDraw.Draw(text).text(
        (4 - bounds[0], 4 - bounds[1]), label, font=font, fill="white"
    )
    text = text.rotate(-45, Image.Resampling.BICUBIC, expand=True)
    center = (width - round(unit * 0.183), round(unit * 0.183))
    layer.alpha_composite(
        text, (center[0] - text.width // 2, center[1] - text.height // 2)
    )
    return Image.alpha_composite(image.convert("RGBA"), layer).convert("RGB")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--channel", choices=tuple(COLORS), required=True)
    args = parser.parse_args()

    with Image.open(args.input) as source:
        cover = add_ribbon(source, args.channel)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    cover.save(args.output, format="PNG", optimize=True)


if __name__ == "__main__":
    main()
