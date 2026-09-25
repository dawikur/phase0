# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import json
from pathlib import Path
from typing import Sequence

from scripts.utils.store_screenshots import Scenario


def build_site_screenshots(scenarios: Sequence[Scenario], output: Path) -> None:
    """Write the screenshot gallery metadata as a browser-ready JavaScript file."""
    screenshots = []
    for scenario in scenarios:
        if not scenario.title or not scenario.description or not scenario.alt:
            raise ValueError(
                f"Screenshot scenario '{scenario.name}' needs a title, description, "
                "and alt text for the website gallery."
            )
        if scenario.preview_size not in {"normal", "small"}:
            raise ValueError(
                f"Screenshot scenario '{scenario.name}' has unsupported preview "
                f"size '{scenario.preview_size}'."
            )
        screenshots.append(
            {
                "name": scenario.name,
                "title": scenario.title,
                "description": scenario.description,
                "alt": scenario.alt,
                "aodAlt": f"{scenario.alt} in always-on mode",
                "previewSize": scenario.preview_size,
            }
        )

    payload = json.dumps(screenshots, ensure_ascii=False)
    payload = (
        payload.replace("<", "\\u003c")
        .replace("\u2028", "\\u2028")
        .replace("\u2029", "\\u2029")
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(f"window.PHASE_SCREENSHOTS = {payload};\n", encoding="utf-8")
