# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

from scripts.utils.app_channels import render_manifest


def test_generated_manifest_uses_explicit_source_path() -> None:
    jungle = Path("monkey.jungle").read_text(encoding="utf-8").splitlines()
    source_setting = next(
        line for line in jungle if line.startswith("base.sourcePath = ")
    )
    source = Path(source_setting.removeprefix("base.sourcePath = "))
    assert source.is_dir()
    resource_setting = next(
        line for line in jungle if line.startswith("base.resourcePath = ")
    )
    assert all(
        Path(path).is_dir()
        for path in resource_setting.removeprefix("base.resourcePath = ").split(";")
    )

    manifest = ET.fromstring(render_manifest(Path("manifest.xml.tmpl"), "developer"))
    application = manifest.find("{http://www.garmin.com/xml/connectiq}application")
    assert application is not None
    entry = application.attrib["entry"]
    assert any(
        f"class {entry} extends" in file.read_text(encoding="utf-8")
        for file in source.rglob("*.mc")
    )


@pytest.mark.parametrize(
    ("target", "channel", "package"),
    (
        ("alpha", "alpha", "phase0-alpha.iq"),
        ("beta", "beta", "phase0-beta.iq"),
        ("iq", "release", "phase0.iq"),
    ),
)
@pytest.mark.parametrize("mode", (None, "release"))
def test_package_helpers_use_release_mode(
    target: str, channel: str, package: str, mode: str | None
) -> None:
    command = ["make", "-n", target]
    if mode is not None:
        command.append(f"MODE={mode}")
    result = subprocess.run(command, capture_output=True, text=True, check=False)

    assert result.returncode == 0, result.stderr
    assert f"MODE=release CHANNEL={channel} build/{package}" in result.stdout
    assert "--release" in result.stdout


@pytest.mark.parametrize("target", ("alpha", "beta", "iq"))
@pytest.mark.parametrize("mode", ("debug", "test", "optimized"))
def test_package_helpers_reject_other_explicit_modes(target: str, mode: str) -> None:
    result = subprocess.run(
        ["make", "-n", target, f"MODE={mode}"],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode != 0
    assert "alpha, beta and iq require MODE=release" in result.stderr


def test_device_build_retains_debug_mode() -> None:
    result = subprocess.run(
        ["make", "-B", "-n", "build", "MODE=debug"],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0, result.stderr
    assert "phase0-fr955_developer.prg" in result.stdout
