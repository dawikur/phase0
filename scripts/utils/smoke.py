# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import os
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from threading import Event, Thread
from typing import Any, TextIO

CONNECT_IQ_NAMESPACE = {"iq": "http://www.garmin.com/xml/connectiq"}
SIMULATOR_START_DELAY = 3
SIMULATOR_STOP_TIMEOUT = 3
WATCH_FACE_START_TIMEOUT = 30
APP_CRASH_MARKER = "Encountered an app crash."
APP_READY_MARKER = "Phase0 initialized"
LINE_BUFFER_COMMAND = ("stdbuf", "-oL", "-eL")
ANSI_REVERSE = "\033[7m"
ANSI_RESET = "\033[0m"


class ApplicationCrashError(RuntimeError):
    """Raised when Connect IQ reports that the watch face has crashed."""


class ApplicationStartError(RuntimeError):
    """Raised when the watch face does not signal that it has initialized."""


@dataclass
class SmokeSignals:
    crashed: Event
    ready: Event | None = None


@dataclass
class Simulator:
    process: subprocess.Popen[str]
    signals: SmokeSignals
    output_thread: Thread


@dataclass
class WatchFaceLoader:
    process: subprocess.Popen[str]
    output_thread: Thread


def supported_devices(manifest: Path) -> list[str]:
    """Return Connect IQ product IDs in manifest order."""
    root = ET.parse(manifest).getroot()
    return [
        product_id
        for product in root.findall(".//iq:products/iq:product", CONNECT_IQ_NAMESPACE)
        if (product_id := product.get("id"))
    ]


def connect_iq_sdk_dir() -> Path:
    """Read the active Connect IQ SDK directory from Garmin's configuration."""
    config = Path.home() / ".Garmin" / "ConnectIQ" / "current-sdk.cfg"
    return Path(config.read_text(encoding="utf-8").strip())


def run_smoke_test(
    manifest: Path,
    make: str,
    name: str,
    build_dir: Path,
    sdk_dir: Path | None,
    simulator_duration: float,
    mode: str = "release",
) -> None:
    """Run each build in one shared simulator instance."""  # pylint: disable=too-many-arguments,too-many-positional-arguments
    sdk_dir = sdk_dir or connect_iq_sdk_dir()
    sdk_bin = sdk_dir / "bin"
    simulator: Simulator | None = None

    try:
        simulator = _start_simulator(sdk_bin / "connectiq")
        for device in supported_devices(manifest):
            print(f"\n {ANSI_REVERSE}[ {device} ]{ANSI_RESET} ", flush=True)
            _build(make, name, device, mode)
            simulator.signals.ready = Event()
            monkeydo = _start_watch_face(
                sdk_bin / "monkeydo",
                build_dir,
                name,
                device,
                mode,
                simulator.signals,
            )
            try:
                _wait_for_watch_face(simulator, device)
                _wait_for_crash(simulator, simulator_duration, device)
            finally:
                _stop_watch_face_loader(monkeydo)
            _check_simulator(simulator, device)
    finally:
        if simulator is not None:
            _stop_simulator(simulator)


def _start_simulator(
    connectiq: Path,
    *,
    env_overrides: Mapping[str, str] | None = None,
    cwd: Path | None = None,
) -> Simulator:
    """Start Connect IQ once and ensure it remains alive during startup."""
    signals = SmokeSignals(Event())
    process, output_thread = _start_logged_process(
        [str(connectiq)], signals, env_overrides=env_overrides, cwd=cwd
    )
    simulator = Simulator(process, signals, output_thread)
    time.sleep(SIMULATOR_START_DELAY)
    _check_simulator(simulator)
    return simulator


def _build(make: str, name: str, device: str, mode: str) -> None:
    subprocess.run(
        [make, f"build_{mode}", f"NAME={name}", f"DEVICE={device}"], check=True
    )


def _start_watch_face(
    monkeydo: Path,
    build_dir: Path,
    name: str,
    device: str,
    mode: str,
    signals: SmokeSignals,
) -> WatchFaceLoader:
    """Start a watch-face process with the selected test options."""  # pylint: disable=too-many-arguments,too-many-positional-arguments
    output_name = f"{name}-{device}_{mode}"
    settings = build_dir / f"{output_name}-settings.json"
    command = [
        str(monkeydo),
        str(build_dir / f"{output_name}.prg"),
        device,
        "-a",
        f"{settings}:GARMIN/Settings/{settings.name}",
    ]
    if mode == "test":
        command.append("-t")
    process, output_thread = _start_logged_process(command, signals)
    return WatchFaceLoader(process, output_thread)


def _start_logged_process(
    command: list[str],
    signals: SmokeSignals,
    *,
    env_overrides: Mapping[str, str] | None = None,
    cwd: Path | None = None,
) -> tuple[subprocess.Popen[str], Thread]:
    """Start a simulator process with line-buffered output monitoring."""
    # The caller owns the live process and stops it explicitly after the smoke test.
    # pylint: disable=consider-using-with
    process_arguments: dict[str, Any] = {
        "stdout": subprocess.PIPE,
        "stderr": subprocess.STDOUT,
        "text": True,
        "bufsize": 1,
    }
    if env_overrides:
        environment = os.environ.copy()
        environment.update(env_overrides)
        process_arguments["env"] = environment
    if cwd is not None:
        process_arguments["cwd"] = cwd
    process = subprocess.Popen([*LINE_BUFFER_COMMAND, *command], **process_arguments)
    output_thread = Thread(
        target=_watch_simulator_output,
        args=(process.stdout, signals),
        daemon=True,
    )
    output_thread.start()
    return process, output_thread


def _watch_simulator_output(output: TextIO | None, signals: SmokeSignals) -> None:
    """Relay simulator output and record smoke-test lifecycle markers."""
    if output is None:
        return

    with output:
        for line in output:
            print(line, end="", file=sys.stdout, flush=True)
            if APP_CRASH_MARKER in line:
                signals.crashed.set()
                if signals.ready is not None:
                    signals.ready.set()
            if APP_READY_MARKER in line and signals.ready is not None:
                signals.ready.set()


def _check_simulator(simulator: Simulator, device: str | None = None) -> None:
    if simulator.signals.crashed.is_set():
        message = "Connect IQ reported an application crash"
        if device is not None:
            message += f" on {device}"
        raise ApplicationCrashError(message)

    return_code = simulator.process.poll()
    if return_code is not None:
        raise subprocess.CalledProcessError(return_code, simulator.process.args)


def _wait_for_crash(simulator: Simulator, duration: float, device: str) -> None:
    """Wait for an interval, returning early when the watch face crashes."""
    if simulator.signals.crashed.wait(timeout=duration):
        _check_simulator(simulator, device)


def _wait_for_watch_face(simulator: Simulator, device: str) -> None:
    """Wait until the current watch face has completed initialization."""
    ready = simulator.signals.ready
    if ready is None or not ready.wait(timeout=WATCH_FACE_START_TIMEOUT):
        raise ApplicationStartError(
            f"Connect IQ did not report watch face initialization on {device}"
        )
    _check_simulator(simulator, device)


def _stop_simulator(simulator: Simulator) -> None:
    """Stop the shared Connect IQ simulator before exiting."""
    _stop_process(simulator.process)
    simulator.output_thread.join(timeout=SIMULATOR_STOP_TIMEOUT)


def _stop_watch_face_loader(loader: WatchFaceLoader) -> None:
    _stop_process(loader.process)
    loader.output_thread.join(timeout=SIMULATOR_STOP_TIMEOUT)


def _stop_process(process: subprocess.Popen[str]) -> None:
    """Stop a simulator-related process, waiting briefly for a clean exit."""
    if process.poll() is None:
        process.terminate()

    try:
        process.wait(timeout=SIMULATOR_STOP_TIMEOUT)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
