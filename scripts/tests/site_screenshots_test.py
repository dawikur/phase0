# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from dataclasses import replace
from pathlib import Path

import pytest

from scripts.tests.javascript_helpers import window_value
from scripts.utils.site_screenshots import build_site_screenshots
from scripts.utils.store_screenshots import Scenario


def test_site_screenshots_writes_gallery_metadata_safely(tmp_path: Path) -> None:
    output = tmp_path / "nested" / "screenshots-data.js"
    scenario = Scenario(
        "preview",
        "fr255",
        {},
        title="Sunrise <view>",
        description="Morning\u2028light",
        alt="Sunrise\u2029watch face",
        preview_size="small",
    )

    build_site_screenshots([scenario], output)

    assert window_value(output, "PHASE_SCREENSHOTS") == [
        {
            "name": "preview",
            "title": "Sunrise <view>",
            "description": "Morning\u2028light",
            "alt": "Sunrise\u2029watch face",
            "aodAlt": "Sunrise\u2029watch face in always-on mode",
            "previewSize": "small",
        }
    ]


@pytest.mark.parametrize(
    "metadata",
    [
        {"title": ""},
        {"description": ""},
        {"alt": ""},
    ],
)
def test_site_screenshots_requires_gallery_text(
    tmp_path: Path, metadata: dict[str, str]
) -> None:
    scenario = Scenario(
        "preview", "fr255", {}, title="Title", description="Description", alt="Alt"
    )
    scenario = replace(scenario, **metadata)

    with pytest.raises(ValueError, match="needs a title, description, and alt text"):
        build_site_screenshots([scenario], tmp_path / "screenshots-data.js")


def test_site_screenshots_rejects_unknown_preview_size(tmp_path: Path) -> None:
    scenario = Scenario(
        "preview",
        "fr255",
        {},
        title="Title",
        description="Description",
        alt="Alt",
        preview_size="large",
    )

    with pytest.raises(ValueError, match="unsupported preview size 'large'"):
        build_site_screenshots([scenario], tmp_path / "screenshots-data.js")
