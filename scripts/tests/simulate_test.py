# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import subprocess
from pathlib import Path

import pytest


@pytest.mark.parametrize(
    ("output", "status", "success"),
    (
        ("PASSED (passed=23, failed=0, errors=0)\n", 1, True),
        ("PASSED (passed=23, failed=0 , errors=0)\r\n", 0, True),
        ("PASSED (passed=23, failed=0, errors=0)\n", 2, False),
        ("FAILED (passed=22, failed=1, errors=0)\n", 1, False),
        ("PASS\n", 0, False),
        ("PASSED (passed=0, failed=0, errors=0)\n", 0, False),
        ("Error: crash\nPASSED (passed=23, failed=0, errors=0)\n", 1, False),
        ("FAIL\nPASSED (passed=23, failed=0, errors=0)\n", 0, False),
    ),
)
def test_simulate_test_summary_and_cleanup(
    tmp_path: Path, output: str, status: int, success: bool
) -> None:
    # Exercise the actual recipe with fake SDK processes; never build or run CIQ.
    makefile = Path("Makefile").read_text(encoding="utf-8")
    recipe = makefile.split("s simulate: build # run simulator\n", 1)[1].split(
        ".PHONY: s simulate", 1
    )[0]
    sdk_bin = tmp_path / "bin"
    sdk_bin.mkdir()
    simulator = sdk_bin / "simulator"
    simulator.write_text(
        f'#!/bin/bash\necho $$ > "{tmp_path}/sim.pid"\nexec /bin/sleep 30\n',
        encoding="utf-8",
    )
    monkeydo = sdk_bin / "monkeydo"
    (tmp_path / "output").write_text(output, encoding="utf-8")
    monkeydo.write_text(
        f'#!/bin/bash\ncat "{tmp_path}/output"\nexit {status}\n', encoding="utf-8"
    )
    simulator.chmod(0o755)
    monkeydo.chmod(0o755)
    isolated = tmp_path / "Makefile"
    isolated.write_text(
        ".ONESHELL:\nSHELL := /bin/bash\n.SHELLFLAGS := -e -o pipefail -c\n"
        f"SDK_DIR := {tmp_path}/\nCONNECTIQ := {simulator}\n"
        f"MONKEYDO := {monkeydo}\nMODE := test\nrun:\n"
        + recipe.replace("\tsleep 3\n", "\t/bin/sleep 0.05\n"),
        encoding="utf-8",
    )
    result = subprocess.run(
        ["make", "--no-print-directory", "-s", "-f", str(isolated), "run"],
        capture_output=True,
        text=True,
        check=False,
        timeout=5,
    )
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    pid = (tmp_path / "sim.pid").read_text(encoding="utf-8").strip()
    probe = subprocess.run(["kill", "-0", pid], capture_output=True, check=False)
    assert probe.returncode != 0
