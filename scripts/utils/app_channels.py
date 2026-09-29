# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Stable Connect IQ identities and manifest rendering for each app channel."""

import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

CHANNELS = {
    "developer": ("5c5797bf-915b-480b-a36b-93fd5b07428a", "APP_NAME_DEVELOPER"),
    "alpha": ("f294c665-ad17-495e-9c19-876c411fcb89", "APP_NAME_ALPHA"),
    "beta": ("acbbdc44-3573-4970-ab72-978ab5656212", "APP_NAME_BETA"),
    "release": ("8f820e83-a1b0-4a36-85f4-fbab5c13bac4", "APP_NAME"),
}


def render_manifest(template: Path, channel: str) -> str:
    if channel not in CHANNELS:
        raise ValueError(f"Unsupported channel: {channel}")
    content = template.read_text(encoding="utf-8")
    if content.count("{ID}") != 1 or content.count("{APP_NAME}") != 1:
        raise ValueError("Manifest template must contain each placeholder exactly once")
    app_id, app_name = CHANNELS[channel]
    rendered = content.replace("{ID}", app_id).replace("{APP_NAME}", app_name)
    root = ET.fromstring(rendered)
    application = root.find("{http://www.garmin.com/xml/connectiq}application")
    if application is None or application.get("id") != app_id:
        raise ValueError("Rendered manifest has no matching application ID")
    if uuid.UUID(app_id).version != 4:
        raise ValueError(f"Invalid version 4 application ID: {app_id}")
    return rendered
