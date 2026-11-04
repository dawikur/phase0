# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

from scripts.utils.app_channels import CHANNELS, render_manifest

TEMPLATE = Path("manifest.xml.tmpl")
APPLICATION = "{http://www.garmin.com/xml/connectiq}application"


def test_rendered_channels_have_distinct_ids_and_shared_configuration() -> None:
    ids = []
    shared = []
    for channel, (expected_id, expected_name) in CHANNELS.items():
        application = ET.fromstring(render_manifest(TEMPLATE, channel)).find(
            APPLICATION
        )
        assert application is not None
        assert application.get("id") == expected_id
        assert application.get("name") == f"@Strings.{expected_name}"
        assert uuid.UUID(expected_id).version == 4
        ids.append(expected_id)
        application.set("id", "")
        application.set("name", "")
        shared.append(ET.tostring(application))
    assert len(set(ids)) == 3
    assert len(set(shared)) == 1


def test_render_manifest_rejects_unknown_channel() -> None:
    with pytest.raises(ValueError, match="Unsupported channel"):
        render_manifest(TEMPLATE, "preview")


def test_render_manifest_rejects_missing_placeholder(tmp_path: Path) -> None:
    template = tmp_path / "manifest.xml.tmpl"
    template.write_text("<manifest id='{ID}' />", encoding="utf-8")
    with pytest.raises(ValueError, match="each placeholder exactly once"):
        render_manifest(template, "alpha")


def test_render_manifest_requires_application(tmp_path: Path) -> None:
    template = tmp_path / "manifest.xml.tmpl"
    template.write_text("<manifest id='{ID}' name='{APP_NAME}' />", encoding="utf-8")
    with pytest.raises(ValueError, match="no matching application ID"):
        render_manifest(template, "alpha")


def test_render_manifest_requires_version_four_uuid(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    template = tmp_path / "manifest.xml.tmpl"
    template.write_text(
        '<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq">'
        '<iq:application id="{ID}" name="{APP_NAME}" /></iq:manifest>',
        encoding="utf-8",
    )
    monkeypatch.setitem(CHANNELS, "beta", (str(uuid.uuid1()), "APP_NAME_BETA"))
    with pytest.raises(ValueError, match="Invalid version 4"):
        render_manifest(template, "beta")


def test_release_preserves_store_identity() -> None:
    application = ET.fromstring(render_manifest(TEMPLATE, "release")).find(APPLICATION)
    assert application is not None
    assert application.get("id") == "acbbdc44-3573-4970-ab72-978ab5656212"
    assert application.get("name") == "@Strings.APP_NAME"
