# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Shared Connect IQ simulator and watch-face process lifecycle."""

import os
import re
import subprocess
import sys
import time
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from threading import Event, Thread
from typing import Any, TextIO

SIMULATOR_START_DELAY = 3
SIMULATOR_STOP_TIMEOUT = 3
WATCH_FACE_START_TIMEOUT = 30
SIMULATOR_POLL_INTERVAL = 0.1
APP_CRASH_MARKER = "Encountered an app crash."
APP_FAILURE_PATTERN = re.compile(r"^\s*(?:Error:|ERROR\b)|\b(?:FAIL|FAILED)\b")
APP_READY_MARKER = "Phase0 initialized"
LINE_BUFFER_COMMAND = ("stdbuf", "-oL", "-eL")


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


def connect_iq_sdk_dir() -> Path:
    """Read the active Connect IQ SDK directory from Garmin's configuration."""
    config = Path.home() / ".Garmin" / "ConnectIQ" / "current-sdk.cfg"
    return Path(config.read_text(encoding="utf-8").strip())


def start_simulator(
    connectiq: Path,
    *,
    env_overrides: Mapping[str, str] | None = None,
    cwd: Path | None = None,
) -> Simulator:
    """Start Connect IQ once and stop it if startup fails."""
    signals = SmokeSignals(Event())
    # The Linux connectiq shell launcher does not exec its simulator child.
    # Own the simulator process directly so stopping it cannot orphan the GUI.
    executable = (
        connectiq.with_name("simulator") if sys.platform == "linux" else connectiq
    )
    process, output_thread = start_logged_process(
        [str(executable)], signals, env_overrides=env_overrides, cwd=cwd
    )
    simulator = Simulator(process, signals, output_thread)
    try:
        time.sleep(SIMULATOR_START_DELAY)
        check_simulator(simulator)
    except BaseException:
        stop_simulator(simulator)
        raise
    return simulator


def start_logged_process(
    command: list[str],
    signals: SmokeSignals,
    *,
    env_overrides: Mapping[str, str] | None = None,
    cwd: Path | None = None,
) -> tuple[subprocess.Popen[str], Thread]:
    """Start a process with line-buffered output monitoring."""
    # The caller owns the live process and stops it explicitly.
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
        target=watch_simulator_output,
        args=(process.stdout, signals),
        daemon=True,
    )
    try:
        output_thread.start()
    except BaseException:
        stop_process(process)
        raise
    return process, output_thread


def watch_simulator_output(output: TextIO | None, signals: SmokeSignals) -> None:
    """Relay simulator output and record lifecycle markers."""
    if output is None:
        return

    with output:
        for line in output:
            print(line, end="", file=sys.stdout, flush=True)
            if APP_CRASH_MARKER in line or APP_FAILURE_PATTERN.search(line):
                signals.crashed.set()
                if signals.ready is not None:
                    signals.ready.set()
            if APP_READY_MARKER in line and signals.ready is not None:
                signals.ready.set()


def check_simulator(simulator: Simulator, device: str | None = None) -> None:
    if simulator.signals.crashed.is_set():
        message = "Connect IQ reported an application crash"
        if device is not None:
            message += f" on {device}"
        raise ApplicationCrashError(message)

    return_code = simulator.process.poll()
    if return_code is not None:
        raise subprocess.CalledProcessError(return_code, simulator.process.args)


def wait_for_crash(simulator: Simulator, duration: float, device: str) -> None:
    """Watch for app crashes and simulator exit during an interval."""
    deadline = time.monotonic() + duration
    while True:
        check_simulator(simulator, device)
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return
        simulator.signals.crashed.wait(timeout=min(remaining, SIMULATOR_POLL_INTERVAL))


def wait_for_watch_face(simulator: Simulator, device: str) -> None:
    """Wait until the current watch face has completed initialization."""
    ready = simulator.signals.ready
    if ready is None:
        raise ApplicationStartError(
            f"Connect IQ did not report watch face initialization on {device}"
        )
    deadline = time.monotonic() + WATCH_FACE_START_TIMEOUT
    while True:
        check_simulator(simulator, device)
        if ready.is_set():
            return
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise ApplicationStartError(
                f"Connect IQ did not report watch face initialization on {device}"
            )
        ready.wait(timeout=min(remaining, SIMULATOR_POLL_INTERVAL))


def stop_simulator(simulator: Simulator) -> None:
    """Stop the shared Connect IQ simulator before exiting."""
    stop_process(simulator.process)
    simulator.output_thread.join(timeout=SIMULATOR_STOP_TIMEOUT)


def stop_watch_face_loader(loader: WatchFaceLoader) -> None:
    stop_process(loader.process)
    loader.output_thread.join(timeout=SIMULATOR_STOP_TIMEOUT)


def stop_process(process: subprocess.Popen[str]) -> None:
    """Stop a simulator-related process, waiting briefly for a clean exit."""
    if process.poll() is None:
        process.terminate()

    try:
        process.wait(timeout=SIMULATOR_STOP_TIMEOUT)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
