# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import subprocess
from pathlib import Path

import pytest


def test_jungle_paths_point_to_existing_source_and_resource_directories() -> None:
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
