# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import subprocess
from pathlib import Path
from threading import Event

from scripts.utils.manifest import supported_connect_iq_ids as supported_devices
from scripts.utils.simulator_process import (
    Simulator,
    SmokeSignals,
    WatchFaceLoader,
    check_simulator,
    connect_iq_sdk_dir,
    start_logged_process,
    start_simulator,
    stop_simulator,
    stop_watch_face_loader,
    wait_for_crash,
    wait_for_watch_face,
)

ANSI_REVERSE = "\033[7m"
ANSI_RESET = "\033[0m"


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
        simulator = start_simulator(sdk_bin / "connectiq")
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
                wait_for_watch_face(simulator, device)
                wait_for_crash(simulator, simulator_duration, device)
            finally:
                stop_watch_face_loader(monkeydo)
            check_simulator(simulator, device)
    finally:
        if simulator is not None:
            stop_simulator(simulator)


def _build(make: str, name: str, device: str, mode: str) -> None:
    subprocess.run(
        [make, f"build_{mode}", f"NAME={name}", f"DEVICE={device}", "CHANNEL=release"],
        check=True,
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
        f"{settings}:GARMIN/Settings/{output_name.upper()}-settings.json",
    ]
    if mode == "test":
        command.append("-t")
    process, output_thread = start_logged_process(command, signals)
    return WatchFaceLoader(process, output_thread)
