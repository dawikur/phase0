# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import json
import os
import re
import shutil
import subprocess
import sys
import time
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from threading import Event
from typing import Iterator, Mapping, Sequence
from uuid import uuid4

from PIL import Image

from scripts.utils.smoke import (
    Simulator,
    SmokeSignals,
    WatchFaceLoader,
    _check_simulator,
    _start_logged_process,
    _start_simulator,
    _stop_simulator,
    _stop_watch_face_loader,
    _wait_for_watch_face,
    connect_iq_sdk_dir,
    supported_devices,
)

REPO_DIR = Path(__file__).resolve().parents[2]
VIEW_SOURCE = REPO_DIR / "source" / "phase0" / "view.mc"
SIMULATOR_WINDOW_RE = re.compile(r"(?:connect iq|ciq).*simulator", re.IGNORECASE)
SCENARIO_NAME_RE = re.compile(r"[a-z0-9][a-z0-9_-]*\Z")
WINDOW_WAIT_TIMEOUT = 30
SCREENSHOT_DIALOG_TIMEOUT = 10
SCREENSHOT_FILE_TIMEOUT = 30
SIMULATOR_CLOSE_TIMEOUT = 5
SCREENSHOT_DIALOG_RE = re.compile(
    r"save (?:screenshot|screen capture)|save as", re.IGNORECASE
)


def _print_status(message: str) -> None:
    """Print a bold progress message when writing directly to a terminal."""
    if sys.stdout.isatty():
        message = f"\033[1m{message}\033[0m"
    print(message, flush=True)


@dataclass(frozen=True)
class Scenario:
    name: str
    device: str
    properties: Mapping[str, int | bool]
    title: str = ""
    description: str = ""
    alt: str = ""
    preview_size: str = "normal"


def validate_scenarios(
    scenarios: Sequence[Scenario],
    devices: Sequence[str],
    selected_names: Sequence[str] | None = None,
) -> list[Scenario]:
    """Validate configured names and devices, then select scenarios in config order."""
    names: set[str] = set()
    for scenario in scenarios:
        if not SCENARIO_NAME_RE.fullmatch(scenario.name):
            raise ValueError(
                f"Invalid screenshot scenario name '{scenario.name}'; "
                "use lowercase letters, digits, '-' and '_'."
            )
        if scenario.name in names:
            raise ValueError(f"Duplicate screenshot scenario '{scenario.name}'.")
        names.add(scenario.name)
        if scenario.device not in devices:
            raise ValueError(
                f"Screenshot scenario '{scenario.name}' uses unsupported device "
                f"'{scenario.device}'."
            )

    if selected_names is None:
        return list(scenarios)

    unknown = set(selected_names) - names
    if unknown:
        raise ValueError(
            "Unknown screenshot scenario(s): " + ", ".join(sorted(unknown))
        )
    selected = set(selected_names)
    return [scenario for scenario in scenarios if scenario.name in selected]


def apply_property_overrides(
    settings_file: Path,
    overrides: Mapping[str, int | bool],
) -> None:
    """Apply validated scenario overrides to the compiler-generated settings JSON."""
    settings = json.loads(settings_file.read_text(encoding="utf-8"))
    if not isinstance(settings, dict):
        raise ValueError(f"Expected a JSON object in {settings_file}.")
    groups = settings.get("settings")
    if not isinstance(groups, list):
        raise ValueError(f"Expected a settings list in {settings_file}.")

    entries: dict[str, dict[str, object]] = {}
    for section in groups:
        if not isinstance(section, dict):
            continue
        group = section.get("group")
        if not isinstance(group, dict):
            continue
        group_entries = group.get("entries")
        if not isinstance(group_entries, list):
            continue
        for entry in group_entries:
            if isinstance(entry, dict) and isinstance(entry.get("key"), str):
                entries[entry["key"]] = entry

    for key, value in overrides.items():
        if key not in entries:
            raise ValueError(
                f"Unknown setting property '{key}' in scenario; "
                f"it is not present in {settings_file.name}."
            )
        current_value = entries[key].get("defaultValue")
        if type(current_value) is not type(value):
            raise ValueError(
                f"Setting property '{key}' expects {type(current_value).__name__}, "
                f"got {type(value).__name__}."
            )
        entries[key]["defaultValue"] = value

    settings_file.write_text(
        json.dumps(settings, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def clear_build_artifacts(build_dir: Path, name: str, device: str) -> None:
    """Remove only one device's release outputs, preserving Store assets and venv."""
    output_name = f"{name}-{device}_release"
    for suffix in (".prg", "-settings.json", ".iq"):
        artifact = build_dir / f"{output_name}{suffix}"
        artifact.unlink(missing_ok=True)
    (build_dir / ".settings.stamp").unlink(missing_ok=True)


@contextmanager
def force_night_mode(enabled: bool) -> Iterator[None]:
    """Force AoD selection only while compiling a screenshot variant."""
    original = VIEW_SOURCE.read_text(encoding="utf-8")
    pattern = re.compile(
        r"(\t\thidden function isNightMode_\(\) as Lang\.Boolean \{\n)"
        r".*?(\n\t\t\})",
        re.DOTALL,
    )
    replacement = f"\t\t\treturn {'true' if enabled else 'false'};"
    updated, count = pattern.subn(
        lambda match: f"{match.group(1)}{replacement}{match.group(2)}",
        original,
        count=1,
    )
    if count != 1:
        raise RuntimeError(f"Could not locate isNightMode_() in {VIEW_SOURCE}.")
    try:
        VIEW_SOURCE.write_text(updated, encoding="utf-8")
        yield
    finally:
        VIEW_SOURCE.write_text(original, encoding="utf-8")


def require_capture_tools() -> None:
    missing = [tool for tool in ("wmctrl", "xdotool") if shutil.which(tool) is None]
    if missing:
        raise RuntimeError(
            "Store screenshot capture requires X11 tools: " + ", ".join(missing)
        )


def require_x11_display() -> None:
    result = subprocess.run(
        ["wmctrl", "-l"], capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or "wmctrl could not access the X11 display"
        raise RuntimeError("Store screenshot capture needs X11: " + detail)


def find_simulator_window(timeout: float = WINDOW_WAIT_TIMEOUT) -> str:
    deadline = time.monotonic() + timeout
    last_windows: list[str] = []
    while time.monotonic() < deadline:
        result = subprocess.run(
            ["wmctrl", "-l"], capture_output=True, text=True, check=True
        )
        last_windows = result.stdout.splitlines()
        matches = [
            line.split(maxsplit=3)[0]
            for line in last_windows
            if len(line.split(maxsplit=3)) == 4
            and SIMULATOR_WINDOW_RE.search(line.split(maxsplit=3)[3])
        ]
        if len(matches) == 1:
            return matches[0]
        if len(matches) > 1:
            raise RuntimeError("More than one Connect IQ Simulator window is open.")
        time.sleep(0.1)
    visible_windows = " | ".join(last_windows) or "wmctrl reported no windows"
    raise RuntimeError(
        "Timed out waiting for the Connect IQ Simulator window. "
        f"Windows reported by wmctrl -l: {visible_windows}"
    )


def _xdotool(*arguments: str) -> None:
    subprocess.run(["xdotool", *arguments], check=True)


def reset_simulator_app_data() -> None:
    """Clear saved properties and restart the current app through the simulator."""
    window_id = find_simulator_window()
    subprocess.run(["wmctrl", "-ia", window_id], check=True)
    _xdotool("key", "--clearmodifiers", "alt+f")
    time.sleep(0.15)
    _xdotool("key", "--clearmodifiers", "r")
    time.sleep(0.15)
    _xdotool("key", "--clearmodifiers", "r")
    time.sleep(0.15)
    _xdotool("key", "--clearmodifiers", "Return")
    time.sleep(0.15)


def _wait_for_window(title_re: re.Pattern[str], timeout: float) -> str | None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = subprocess.run(
            ["wmctrl", "-l"], capture_output=True, text=True, check=True
        )
        for line in result.stdout.splitlines():
            parts = line.split(maxsplit=3)
            if len(parts) == 4 and title_re.search(parts[3]):
                return parts[0]
        time.sleep(0.1)
    return None


def close_simulator_windows(timeout: float = SIMULATOR_CLOSE_TIMEOUT) -> None:
    """Close screenshot dialogs and simulator windows opened by this workflow."""

    def matching_windows() -> list[tuple[str, str]]:
        result = subprocess.run(
            ["wmctrl", "-l"], capture_output=True, text=True, check=True
        )
        windows = []
        for line in result.stdout.splitlines():
            parts = line.split(maxsplit=3)
            if len(parts) == 4 and (
                SIMULATOR_WINDOW_RE.search(parts[3])
                or SCREENSHOT_DIALOG_RE.search(parts[3])
            ):
                windows.append((parts[0], parts[3]))
        return windows

    windows = matching_windows()
    if not windows:
        return

    _print_status("Closing the screenshot dialog and simulator...")
    for window_id, _title in sorted(
        windows, key=lambda window: bool(SIMULATOR_WINDOW_RE.search(window[1]))
    ):
        subprocess.run(["wmctrl", "-ic", window_id], check=True)

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if not matching_windows():
            return
        time.sleep(0.1)
    raise RuntimeError("Timed out waiting for the Connect IQ Simulator to close.")


def capture_simulator_screenshot(output: Path) -> Path:
    """Save the simulator's native device-screen capture to ``output``."""
    output.parent.mkdir(parents=True, exist_ok=True)
    _print_status("Waiting for the Connect IQ Simulator window...")
    window_id = find_simulator_window()
    temporary_output = REPO_DIR / f"phase0-store-shot-{uuid4().hex}.png"
    try:
        _print_status("Opening the simulator's Save Screenshot command...")
        subprocess.run(["wmctrl", "-ia", window_id], check=True)
        _xdotool("key", "--clearmodifiers", "alt+f")
        time.sleep(0.15)
        _xdotool("key", "--clearmodifiers", "s")
        time.sleep(0.15)
        _xdotool("key", "--clearmodifiers", "Return")

        _print_status("Waiting for the screenshot save dialog...")
        dialog_id = _wait_for_window(
            re.compile(r"save (?:screenshot|screen capture)|save as", re.IGNORECASE),
            SCREENSHOT_DIALOG_TIMEOUT,
        )
        if dialog_id is None:
            raise RuntimeError(
                "Could not open the simulator's Save Screenshot dialog. "
                "The simulator may use different File menu shortcuts in this SDK."
            )

        _print_status("Saving the native simulator screenshot...")
        subprocess.run(["wmctrl", "-ia", dialog_id], check=True)
        _xdotool("type", "--clearmodifiers", "--delay", "1", temporary_output.name)
        _print_status("Waiting for the filename to validate...")
        time.sleep(1.5)
        _print_status("Confirming screenshot save...")
        _xdotool("key", "--clearmodifiers", "Return")
        time.sleep(0.5)
        if not temporary_output.is_file() and _wait_for_window(
            SCREENSHOT_DIALOG_RE, timeout=0.2
        ):
            _print_status("Save dialog is still open; confirming once more...")
            _xdotool("key", "--clearmodifiers", "Return")

        deadline = time.monotonic() + SCREENSHOT_FILE_TIMEOUT
        valid_image = False
        invalid_image_error: OSError | ValueError | None = None
        while True:
            if temporary_output.is_file():
                try:
                    with Image.open(temporary_output) as image:
                        image.verify()
                    valid_image = True
                except (OSError, ValueError) as error:
                    invalid_image_error = error
            if valid_image:
                break
            if time.monotonic() >= deadline:
                break
            time.sleep(0.1)
        if not temporary_output.is_file():
            raise RuntimeError("The simulator did not create the screenshot file.")
        if not valid_image:
            raise RuntimeError(
                "The simulator screenshot is not a valid image."
            ) from invalid_image_error

        output.write_bytes(temporary_output.read_bytes())
    finally:
        temporary_output.unlink(missing_ok=True)
    return output


def _build_scenario(
    scenario: Scenario,
    *,
    make: str,
    name: str,
    build_dir: Path,
    night_mode: bool = False,
) -> Path:
    _print_status(
        f"Applying {len(scenario.properties)} setting overrides before compilation..."
    )
    clear_build_artifacts(build_dir, name, scenario.device)
    environment = os.environ.copy()
    environment["PHASE0_STORE_SCREENSHOT_OVERRIDES"] = json.dumps(scenario.properties)
    with force_night_mode(night_mode):
        subprocess.run(
            [make, "build_release", f"NAME={name}", f"DEVICE={scenario.device}"],
            cwd=REPO_DIR,
            check=True,
            env=environment,
        )
    settings = build_dir / f"{name}-{scenario.device}_release-settings.json"
    if not settings.is_file():
        raise RuntimeError(f"Build did not produce settings file {settings}.")
    apply_property_overrides(settings, scenario.properties)
    return settings


def _restore_default_settings(make: str, build_dir: Path) -> None:
    """Regenerate normal settings resources after scenario-specific builds."""
    build_dir = build_dir.resolve()
    try:
        relative_build_dir = build_dir.relative_to(REPO_DIR)
    except ValueError:
        return
    stamp = build_dir / ".settings.stamp"
    stamp.unlink(missing_ok=True)
    _print_status("Restoring default generated settings...")
    environment = os.environ.copy()
    environment.pop("PHASE0_STORE_SCREENSHOT_OVERRIDES", None)
    subprocess.run(
        [make, str(relative_build_dir / ".settings.stamp")],
        cwd=REPO_DIR,
        check=True,
        env=environment,
    )


# pylint: disable=too-many-arguments
def _start_watch_face(
    monkeydo: Path,
    *,
    scenario: Scenario,
    settings: Path,
    signals: SmokeSignals,
    program: Path,
) -> WatchFaceLoader:
    command = [
        str(monkeydo),
        str(program),
        scenario.device,
        "-a",
        f"{settings}:GARMIN/Settings/{program.stem.upper()}-settings.json",
    ]
    process, output_thread = _start_logged_process(command, signals)
    return WatchFaceLoader(process, output_thread)


# pylint: disable=too-many-arguments
def run_scenario(
    scenario: Scenario,
    *,
    make: str,
    name: str,
    build_dir: Path,
    sdk_dir: Path,
    output_dir: Path,
    simulator: Simulator,
    night_mode: bool = False,
) -> Path:
    view_name = "AoD" if night_mode else "normal"
    output_name = f"{scenario.name}-aod.png" if night_mode else f"{scenario.name}.png"
    _print_status(
        f"Building {view_name} screenshot for '{scenario.name}' on {scenario.device}..."
    )
    settings = _build_scenario(
        scenario,
        make=make,
        name=name,
        build_dir=build_dir,
        night_mode=night_mode,
    )
    program = build_dir / f"{name}-{scenario.device}_release.prg"
    loader = None
    try:
        simulator.signals.ready = Event()
        loader = _start_watch_face(
            sdk_dir / "bin" / "monkeydo",
            scenario=scenario,
            settings=settings,
            signals=simulator.signals,
            program=program,
        )
        _print_status("Waiting for phase0 to finish initializing...")
        _wait_for_watch_face(simulator, scenario.device)
        _print_status("Resetting simulator app data to load scenario defaults...")
        simulator.signals.ready = Event()
        reset_simulator_app_data()
        _wait_for_watch_face(simulator, scenario.device)
        _check_simulator(simulator, scenario.device)
        _print_status("phase0 is ready; capturing screenshot...")
        output = capture_simulator_screenshot(output_dir / output_name)
        _print_status(f"Saved {output}")
        return output
    finally:
        if loader is not None:
            _stop_watch_face_loader(loader)


# pylint: disable=too-many-arguments
def generate_screenshots(
    scenarios: Sequence[Scenario],
    *,
    manifest: Path,
    make: str,
    name: str,
    build_dir: Path,
    sdk_dir: Path | None,
    output_dir: Path,
    selected_names: Sequence[str] | None = None,
) -> list[Path]:
    devices = supported_devices(manifest)
    selected = validate_scenarios(scenarios, devices, selected_names)
    if not selected:
        return []
    require_capture_tools()
    require_x11_display()
    sdk_dir = sdk_dir or connect_iq_sdk_dir()
    try:
        _print_status("Starting Connect IQ Simulator...")
        simulator = _start_simulator(
            sdk_dir / "bin" / "connectiq",
            env_overrides={"GDK_BACKEND": "x11"},
            cwd=REPO_DIR,
        )
        try:
            outputs = []
            for scenario in selected:
                for night_mode in (False, True):
                    outputs.append(
                        run_scenario(
                            scenario,
                            make=make,
                            name=name,
                            build_dir=build_dir,
                            sdk_dir=sdk_dir,
                            output_dir=output_dir,
                            simulator=simulator,
                            night_mode=night_mode,
                        )
                    )
            return outputs
        finally:
            try:
                close_simulator_windows()
            finally:
                _stop_simulator(simulator)
    finally:
        _restore_default_settings(make, build_dir)
