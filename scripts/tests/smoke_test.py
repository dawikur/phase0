# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import importlib.machinery
import importlib.util
import subprocess
import sys
from argparse import Namespace
from io import StringIO
from pathlib import Path
from threading import Event, Thread
from types import ModuleType
from unittest.mock import MagicMock, call, patch

import pytest

from scripts.utils.smoke import (
    ApplicationCrashError,
    Simulator,
    SmokeSignals,
    _check_simulator,
    _wait_for_crash,
    _watch_simulator_output,
    run_smoke_test,
    supported_devices,
)


def load_smoke_cli() -> ModuleType:
    script = Path("scripts/smoke")
    loader = importlib.machinery.SourceFileLoader("smoke_cli", str(script))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(script.parent))
    try:
        loader.exec_module(module)
    finally:
        sys.path.pop(0)
    return module


def test_supported_devices_reads_product_ids_in_manifest_order(tmp_path: Path) -> None:
    manifest = tmp_path / "manifest.xml"
    manifest.write_text(
        """
        <iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq">
            <iq:application>
                <iq:products>
                    <iq:product id="fr255" />
                    <iq:product id="fenix7x" />
                </iq:products>
            </iq:application>
        </iq:manifest>
        """,
        encoding="utf-8",
    )

    assert supported_devices(manifest) == ["fr255", "fenix7x"]


def test_smoke_cli_handles_keyboard_interrupt(
    capsys: pytest.CaptureFixture[str],
) -> None:
    cli = load_smoke_cli()
    arguments = Namespace(
        manifest=Path("manifest.xml"),
        make="make",
        name="phase0",
        build_dir=Path("build"),
        sdk_dir=None,
        simulator_duration=10,
    )

    with (
        patch.object(cli, "parse_arguments", return_value=arguments),
        patch.object(cli, "run_smoke_test", side_effect=KeyboardInterrupt),
    ):
        assert cli.main() == 130

    assert capsys.readouterr().err == "Smoke test interrupted.\n"


@patch("scripts.utils.smoke.time.sleep")
@patch("scripts.utils.smoke.subprocess.run")
@patch("scripts.utils.smoke.subprocess.Popen")
def test_run_smoke_test_reuses_one_simulator_for_all_devices(
    popen: MagicMock,
    run: MagicMock,
    sleep: MagicMock,
    tmp_path: Path,
) -> None:
    manifest = tmp_path / "manifest.xml"
    manifest.write_text(
        """
        <iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq">
            <iq:products>
                <iq:product id="fr255" />
                <iq:product id="fenix7x" />
            </iq:products>
        </iq:manifest>
        """,
        encoding="utf-8",
    )
    sdk_dir = tmp_path / "sdk"
    build_dir = tmp_path / "build"
    simulator = MagicMock(args=["connectiq"])
    first_monkeydo = MagicMock(args=["monkeydo", "fr255"])
    second_monkeydo = MagicMock(args=["monkeydo", "fenix7x"])
    simulator.poll.return_value = None
    first_monkeydo.poll.return_value = None
    second_monkeydo.poll.return_value = None
    popen.side_effect = [simulator, first_monkeydo, second_monkeydo]

    with (
        patch("scripts.utils.smoke._wait_for_watch_face") as wait_for_watch_face,
        patch("scripts.utils.smoke._wait_for_crash") as wait_for_crash,
    ):
        run_smoke_test(
            manifest=manifest,
            make="gmake",
            name="phase0",
            build_dir=build_dir,
            sdk_dir=sdk_dir,
            simulator_duration=10,
        )

    assert popen.call_args_list == [
        call(
            ["stdbuf", "-oL", "-eL", str(sdk_dir / "bin" / "connectiq")],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        ),
        call(
            [
                "stdbuf",
                "-oL",
                "-eL",
                str(sdk_dir / "bin" / "monkeydo"),
                str(build_dir / "phase0-fr255_release.prg"),
                "fr255",
                "-a",
                str(build_dir / "phase0-fr255_release-settings.json")
                + ":GARMIN/Settings/phase0-fr255_release-settings.json",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        ),
        call(
            [
                "stdbuf",
                "-oL",
                "-eL",
                str(sdk_dir / "bin" / "monkeydo"),
                str(build_dir / "phase0-fenix7x_release.prg"),
                "fenix7x",
                "-a",
                str(build_dir / "phase0-fenix7x_release-settings.json")
                + ":GARMIN/Settings/phase0-fenix7x_release-settings.json",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        ),
    ]
    assert run.call_args_list == [
        call(["gmake", "build_release", "NAME=phase0", "DEVICE=fr255"], check=True),
        call(
            ["gmake", "build_release", "NAME=phase0", "DEVICE=fenix7x"],
            check=True,
        ),
    ]
    assert sleep.call_args_list == [call(3)]
    assert [call.args[1] for call in wait_for_watch_face.call_args_list] == [
        "fr255",
        "fenix7x",
    ]
    assert [call.args[1] for call in wait_for_crash.call_args_list] == [10, 10]
    first_monkeydo.terminate.assert_called_once_with()
    first_monkeydo.wait.assert_called_once_with(timeout=3)
    second_monkeydo.terminate.assert_called_once_with()
    second_monkeydo.wait.assert_called_once_with(timeout=3)
    simulator.terminate.assert_called_once_with()
    simulator.wait.assert_called_once_with(timeout=3)


def test_check_simulator_raises_when_watch_face_crashes() -> None:
    process = MagicMock(args=["connectiq"])
    crashed = Event()
    crashed.set()
    simulator = Simulator(process, SmokeSignals(crashed), Thread(target=lambda: None))

    with pytest.raises(ApplicationCrashError, match="application crash on descentmk2"):
        _check_simulator(simulator, "descentmk2")


def test_wait_for_crash_fails_immediately_when_watch_face_crashes() -> None:
    process = MagicMock(args=["connectiq"])
    crashed = Event()
    crashed.set()
    simulator = Simulator(process, SmokeSignals(crashed), Thread(target=lambda: None))

    with pytest.raises(ApplicationCrashError, match="application crash on descentmk2"):
        _wait_for_crash(simulator, 10, "descentmk2")


def test_simulator_output_marks_application_crash(
    capsys: pytest.CaptureFixture[str],
) -> None:
    signals = SmokeSignals(Event(), Event())

    _watch_simulator_output(
        StringIO("Error: Out Of Memory Error\nEncountered an app crash.\n"), signals
    )

    assert signals.crashed.is_set()
    assert signals.ready is not None and signals.ready.is_set()
    assert "Encountered an app crash." in capsys.readouterr().out


def test_simulator_output_marks_watch_face_ready() -> None:
    signals = SmokeSignals(Event(), Event())

    _watch_simulator_output(StringIO("Phase0 initialized\n"), signals)

    assert signals.ready is not None and signals.ready.is_set()
