# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import importlib.machinery
import importlib.util
import subprocess
import sys
from argparse import Namespace
from io import StringIO
from pathlib import Path
from threading import Event, Thread
from types import ModuleType
from typing import Any
from unittest.mock import MagicMock, call, patch

import pytest

from scripts.utils.simulator_process import (
    ApplicationCrashError,
    ApplicationStartError,
    Simulator,
    SmokeSignals,
    check_simulator,
    connect_iq_sdk_dir,
    start_logged_process,
    start_simulator,
    stop_process,
    wait_for_crash,
    wait_for_watch_face,
    watch_simulator_output,
)
from scripts.utils.smoke import (
    _start_watch_face,
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
        mode="release",
    )

    with (
        patch.object(cli, "parse_arguments", return_value=arguments),
        patch.object(cli, "run_smoke_test", side_effect=KeyboardInterrupt),
    ):
        assert cli.main() == 130

    assert capsys.readouterr().err == "Smoke test interrupted.\n"


def test_smoke_cli_returns_zero_when_run_succeeds() -> None:
    cli = load_smoke_cli()
    arguments = Namespace(
        manifest=Path("manifest.xml"),
        make="make",
        name="phase0",
        build_dir=Path("build"),
        sdk_dir=Path("sdk"),
        simulator_duration=10,
        mode="release",
    )

    with (
        patch.object(cli, "parse_arguments", return_value=arguments),
        patch.object(cli, "run_smoke_test") as run,
    ):
        assert cli.main() == 0

    run.assert_called_once_with(
        manifest=arguments.manifest,
        make=arguments.make,
        name=arguments.name,
        build_dir=arguments.build_dir,
        sdk_dir=arguments.sdk_dir,
        simulator_duration=arguments.simulator_duration,
        mode=arguments.mode,
    )


def test_smoke_parser_uses_defaults() -> None:
    cli = load_smoke_cli()

    arguments = cli.parse_arguments([])

    assert arguments.manifest == Path("build/manifests/release.xml")
    assert arguments.build_dir == Path("build")
    assert arguments.simulator_duration == 10
    assert arguments.mode == "release"


@patch("scripts.utils.simulator_process.time.sleep")
@patch("scripts.utils.smoke.subprocess.run")
@patch("scripts.utils.simulator_process.subprocess.Popen")
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
        patch("scripts.utils.smoke.wait_for_watch_face") as wait_for_watch_face_mock,
        patch("scripts.utils.smoke.wait_for_crash") as wait_for_crash_mock,
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
                + ":GARMIN/Settings/PHASE0-FR255_RELEASE-settings.json",
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
                + ":GARMIN/Settings/PHASE0-FENIX7X_RELEASE-settings.json",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        ),
    ]
    assert run.call_args_list == [
        call(
            [
                "gmake",
                "build_release",
                "NAME=phase0",
                "DEVICE=fr255",
                "CHANNEL=release",
            ],
            check=True,
        ),
        call(
            [
                "gmake",
                "build_release",
                "NAME=phase0",
                "DEVICE=fenix7x",
                "CHANNEL=release",
            ],
            check=True,
        ),
    ]
    assert sleep.call_args_list == [call(3)]
    assert [call.args[1] for call in wait_for_watch_face_mock.call_args_list] == [
        "fr255",
        "fenix7x",
    ]
    assert [call.args[1] for call in wait_for_crash_mock.call_args_list] == [10, 10]
    first_monkeydo.terminate.assert_called_once_with()
    first_monkeydo.wait.assert_called_once_with(timeout=3)
    second_monkeydo.terminate.assert_called_once_with()
    second_monkeydo.wait.assert_called_once_with(timeout=3)
    simulator.terminate.assert_called_once_with()
    simulator.wait.assert_called_once_with(timeout=3)


@patch("scripts.utils.smoke.start_logged_process")
def test_start_watch_face_passes_test_mode_to_monkeydo(
    start_logged_process_mock: MagicMock, tmp_path: Path
) -> None:
    process = MagicMock()
    output_thread = Thread(target=lambda: None)
    start_logged_process_mock.return_value = (process, output_thread)
    signals = SmokeSignals(Event())

    loader = _start_watch_face(
        monkeydo=tmp_path / "monkeydo",
        build_dir=tmp_path / "build",
        name="phase0",
        device="fr255",
        mode="test",
        signals=signals,
    )

    assert loader.process is process
    assert loader.output_thread is output_thread
    start_logged_process_mock.assert_called_once_with(
        [
            str(tmp_path / "monkeydo"),
            str(tmp_path / "build" / "phase0-fr255_test.prg"),
            "fr255",
            "-a",
            str(tmp_path / "build" / "phase0-fr255_test-settings.json")
            + ":GARMIN/Settings/PHASE0-FR255_TEST-settings.json",
            "-t",
        ],
        signals,
    )


@patch("scripts.utils.simulator_process.Thread")
@patch("scripts.utils.simulator_process.subprocess.Popen")
def test_start_logged_process_applies_environment_overrides(
    popen: MagicMock, thread: MagicMock
) -> None:
    process = MagicMock()
    popen.return_value = process

    result_process, result_thread = start_logged_process(
        ["connectiq"],
        SmokeSignals(Event()),
        env_overrides={"GDK_BACKEND": "x11"},
        cwd=Path("/tmp"),
    )

    assert result_process is process
    assert result_thread is thread.return_value
    arguments = popen.call_args
    assert arguments.args == (["stdbuf", "-oL", "-eL", "connectiq"],)
    assert arguments.kwargs["env"]["GDK_BACKEND"] == "x11"
    assert arguments.kwargs["cwd"] == Path("/tmp")
    thread.return_value.start.assert_called_once_with()


def test_start_simulator_stops_process_if_startup_check_fails() -> None:
    process = MagicMock()
    output_thread = MagicMock()
    with (
        patch(
            "scripts.utils.simulator_process.start_logged_process",
            return_value=(process, output_thread),
        ),
        patch("scripts.utils.simulator_process.time.sleep"),
        patch(
            "scripts.utils.simulator_process.check_simulator",
            side_effect=RuntimeError("startup failed"),
        ),
        patch("scripts.utils.simulator_process.stop_simulator") as stop,
        pytest.raises(RuntimeError, match="startup failed"),
    ):
        start_simulator(Path("connectiq"))

    stopped_simulator = stop.call_args.args[0]
    assert stopped_simulator.process is process
    assert stopped_simulator.output_thread is output_thread


def test_start_logged_process_stops_process_if_output_thread_fails() -> None:
    process = MagicMock()
    thread = MagicMock()
    thread.start.side_effect = RuntimeError("thread failed")
    with (
        patch("scripts.utils.simulator_process.subprocess.Popen", return_value=process),
        patch("scripts.utils.simulator_process.Thread", return_value=thread),
        patch("scripts.utils.simulator_process.stop_process") as stop,
        pytest.raises(RuntimeError, match="thread failed"),
    ):
        start_logged_process(["connectiq"], SmokeSignals(Event()))

    stop.assert_called_once_with(process)


def test_check_simulator_raises_when_watch_face_crashes() -> None:
    process = MagicMock(args=["connectiq"])
    crashed = Event()
    crashed.set()
    simulator = Simulator(process, SmokeSignals(crashed), Thread(target=lambda: None))

    with pytest.raises(ApplicationCrashError, match="application crash on descentmk2"):
        check_simulator(simulator, "descentmk2")


def test_wait_for_crash_fails_immediately_when_watch_face_crashes() -> None:
    process = MagicMock(args=["connectiq"])
    crashed = Event()
    crashed.set()
    simulator = Simulator(process, SmokeSignals(crashed), Thread(target=lambda: None))

    with pytest.raises(ApplicationCrashError, match="application crash on descentmk2"):
        wait_for_crash(simulator, 10, "descentmk2")


def test_wait_for_crash_detects_stopped_simulator() -> None:
    process = MagicMock(args=["connectiq"])
    process.poll.return_value = 2
    simulator = Simulator(process, SmokeSignals(Event()), Thread(target=lambda: None))

    with pytest.raises(subprocess.CalledProcessError) as error:
        wait_for_crash(simulator, 10, "fr255")

    assert error.value.returncode == 2


def test_wait_for_watch_face_detects_stopped_simulator() -> None:
    process = MagicMock(args=["connectiq"])
    process.poll.return_value = 2
    simulator = Simulator(
        process, SmokeSignals(Event(), Event()), Thread(target=lambda: None)
    )

    with pytest.raises(subprocess.CalledProcessError) as error:
        wait_for_watch_face(simulator, "fr255")

    assert error.value.returncode == 2


def test_simulator_output_marks_application_crash(
    capsys: pytest.CaptureFixture[str],
) -> None:
    signals = SmokeSignals(Event(), Event())

    watch_simulator_output(
        StringIO("Error: Out Of Memory Error\nEncountered an app crash.\n"), signals
    )

    assert signals.crashed.is_set()
    assert signals.ready is not None and signals.ready.is_set()
    assert "Encountered an app crash." in capsys.readouterr().out


def test_simulator_output_marks_watch_face_ready() -> None:
    signals = SmokeSignals(Event(), Event())

    watch_simulator_output(StringIO("Phase0 initialized\n"), signals)

    assert signals.ready is not None and signals.ready.is_set()


def test_smoke_helpers_handle_missing_ready_output_and_process_failures(
    tmp_path,
) -> None:
    config = tmp_path / ".Garmin" / "ConnectIQ" / "current-sdk.cfg"
    config.parent.mkdir(parents=True)
    config.write_text("/opt/connectiq\n", encoding="utf-8")
    with patch("scripts.utils.simulator_process.Path.home", return_value=tmp_path):
        assert connect_iq_sdk_dir() == Path("/opt/connectiq")

    signals = SmokeSignals(Event())
    watch_simulator_output(None, signals)
    process: Any = MagicMock()
    simulator = Simulator(process, signals, Thread(target=lambda: None))
    with pytest.raises(ApplicationStartError, match="initialization on fr255"):
        wait_for_watch_face(simulator, "fr255")

    process.poll.return_value = 2
    with pytest.raises(subprocess.CalledProcessError):
        check_simulator(simulator)

    process.poll.return_value = None
    simulator.signals.ready = Event()
    simulator.signals.ready.set()
    wait_for_watch_face(simulator, "fr255")


def test_stop_process_kills_process_after_timeout() -> None:
    process = MagicMock()
    process.poll.return_value = None
    process.wait.side_effect = [subprocess.TimeoutExpired("connectiq", 3), None]

    stop_process(process)

    process.terminate.assert_called_once_with()
    process.kill.assert_called_once_with()
    assert process.wait.call_count == 2
