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
from typing import Iterator, Literal, Mapping, Sequence
from uuid import uuid4

from PIL import Image

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
    wait_for_watch_face,
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
    time_display: Literal["12h", "24h"] = "24h"
    units_display: Literal["metric", "statute"] = "metric"


@dataclass
class WindowSession:
    simulator_id: str
    owned_ids: set[str]


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
        if scenario.time_display not in ("12h", "24h"):
            raise ValueError(
                f"Screenshot scenario '{scenario.name}' has unsupported time display "
                f"'{scenario.time_display}'."
            )
        if scenario.units_display not in ("metric", "statute"):
            raise ValueError(
                f"Screenshot scenario '{scenario.name}' has unsupported units display "
                f"'{scenario.units_display}'."
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


def list_windows() -> dict[str, str]:
    """Return the current X11 window titles keyed by window ID."""
    result = subprocess.run(
        ["wmctrl", "-l"], capture_output=True, text=True, check=True
    )
    windows = {}
    for line in result.stdout.splitlines():
        parts = line.split(maxsplit=3)
        if len(parts) == 4:
            windows[parts[0]] = parts[3]
    return windows


def find_simulator_window(
    timeout: float = WINDOW_WAIT_TIMEOUT,
    excluded_ids: frozenset[str] = frozenset(),
) -> str:
    deadline = time.monotonic() + timeout
    last_windows: dict[str, str] = {}
    while time.monotonic() < deadline:
        last_windows = list_windows()
        matches = [
            window_id
            for window_id, title in last_windows.items()
            if window_id not in excluded_ids and SIMULATOR_WINDOW_RE.search(title)
        ]
        if len(matches) == 1:
            return matches[0]
        if len(matches) > 1:
            raise RuntimeError("More than one Connect IQ Simulator window is open.")
        time.sleep(0.1)
    visible_windows = " | ".join(last_windows.values()) or "wmctrl reported no windows"
    raise RuntimeError(
        "Timed out waiting for the Connect IQ Simulator window. "
        f"Windows reported by wmctrl -l: {visible_windows}"
    )


def _xdotool(*arguments: str) -> None:
    subprocess.run(["xdotool", *arguments], check=True)


def reset_simulator_app_data(window_id: str | None = None) -> None:
    """Clear saved properties and restart the current app through the simulator."""
    window_id = window_id or find_simulator_window()
    subprocess.run(["wmctrl", "-ia", window_id], check=True)
    _xdotool("key", "--clearmodifiers", "alt+f")
    time.sleep(0.15)
    _xdotool("key", "--clearmodifiers", "r")
    time.sleep(0.15)
    _xdotool("key", "--clearmodifiers", "r")
    time.sleep(0.15)
    _xdotool("key", "--clearmodifiers", "Return")
    time.sleep(0.15)


def set_simulator_display_settings(
    time_display: Literal["12h", "24h"],
    units_display: Literal["metric", "statute"],
    window_id: str | None = None,
) -> None:
    """Set the simulator's global display preferences for one capture."""
    window_id = window_id or find_simulator_window()
    subprocess.run(["wmctrl", "-ia", window_id], check=True)
    # Settings lists Time Display first and Units Display second.
    for menu_offset, choice_offset in (
        (0, 0 if time_display == "12h" else 1),
        (1, 0 if units_display == "metric" else 1),
    ):
        _xdotool("key", "--clearmodifiers", "alt+s")
        time.sleep(0.15)
        _xdotool("key", "Home")
        for _ in range(menu_offset):
            _xdotool("key", "Down")
        _xdotool("key", "Right")
        time.sleep(0.15)
        _xdotool("key", "Home")
        for _ in range(choice_offset):
            _xdotool("key", "Down")
        _xdotool("key", "Return")
        time.sleep(0.15)


def _wait_for_window(
    title_re: re.Pattern[str],
    timeout: float,
    excluded_ids: frozenset[str] = frozenset(),
) -> str | None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        for window_id, title in list_windows().items():
            if window_id not in excluded_ids and title_re.search(title):
                return window_id
        time.sleep(0.1)
    return None


def close_simulator_windows(
    owned_window_ids: set[str], timeout: float = SIMULATOR_CLOSE_TIMEOUT
) -> None:
    """Close screenshot dialogs and simulator windows opened by this workflow."""
    windows = list_windows()
    owned = owned_window_ids & windows.keys()
    if not owned:
        return
    ordered = sorted(
        owned,
        key=lambda window_id: bool(SIMULATOR_WINDOW_RE.search(windows[window_id])),
    )

    _print_status("Closing the screenshot dialog and simulator...")
    for window_id in ordered:
        subprocess.run(["wmctrl", "-ic", window_id], check=True)

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if not owned_window_ids & list_windows().keys():
            return
        time.sleep(0.1)
    raise RuntimeError("Timed out waiting for the Connect IQ Simulator to close.")


def capture_simulator_screenshot(
    output: Path,
    session: WindowSession | None = None,
) -> Path:
    """Save the simulator's native device-screen capture to ``output``."""
    output.parent.mkdir(parents=True, exist_ok=True)
    _print_status("Waiting for the Connect IQ Simulator window...")
    window_id = session.simulator_id if session else find_simulator_window()
    existing_window_ids = (
        frozenset(list_windows()) if session is not None else frozenset()
    )
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
            SCREENSHOT_DIALOG_RE,
            SCREENSHOT_DIALOG_TIMEOUT,
            excluded_ids=existing_window_ids,
        )
        if dialog_id is None:
            raise RuntimeError(
                "Could not open the simulator's Save Screenshot dialog. "
                "The simulator may use different File menu shortcuts in this SDK."
            )
        if session is not None:
            session.owned_ids.add(dialog_id)

        _print_status("Saving the native simulator screenshot...")
        subprocess.run(["wmctrl", "-ia", dialog_id], check=True)
        _xdotool("type", "--clearmodifiers", "--delay", "1", temporary_output.name)
        _print_status("Waiting for the filename to validate...")
        time.sleep(1.5)
        _print_status("Confirming screenshot save...")
        _xdotool("key", "--clearmodifiers", "Return")
        time.sleep(0.5)
        if not temporary_output.is_file() and _wait_for_window(
            SCREENSHOT_DIALOG_RE, timeout=0.2, excluded_ids=existing_window_ids
        ):
            _print_status("Save dialog is still open; confirming once more...")
            _xdotool("key", "--clearmodifiers", "Return")

        _wait_for_valid_screenshot_file(temporary_output)
        output.write_bytes(temporary_output.read_bytes())
    finally:
        temporary_output.unlink(missing_ok=True)
    return output


def _wait_for_valid_screenshot_file(path: Path) -> None:
    deadline = time.monotonic() + SCREENSHOT_FILE_TIMEOUT
    valid_image = False
    invalid_image_error: OSError | ValueError | None = None
    while True:
        if path.is_file():
            try:
                with Image.open(path) as image:
                    image.verify()
                valid_image = True
            except (OSError, ValueError) as error:
                invalid_image_error = error
        if valid_image or time.monotonic() >= deadline:
            break
        time.sleep(0.1)
    if not path.is_file():
        raise RuntimeError("The simulator did not create the screenshot file.")
    if not valid_image:
        raise RuntimeError(
            "The simulator screenshot is not a valid image."
        ) from invalid_image_error


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
            [
                make,
                "build_release",
                f"NAME={name}",
                f"DEVICE={scenario.device}",
                "CHANNEL=release",
            ],
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
    process, output_thread = start_logged_process(command, signals)
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
    window_session: WindowSession,
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
        wait_for_watch_face(simulator, scenario.device)
        _print_status("Setting simulator time and units display...")
        set_simulator_display_settings(
            scenario.time_display, scenario.units_display, window_session.simulator_id
        )
        _print_status("Resetting simulator app data to load scenario defaults...")
        simulator.signals.ready = Event()
        reset_simulator_app_data(window_session.simulator_id)
        wait_for_watch_face(simulator, scenario.device)
        check_simulator(simulator, scenario.device)
        _print_status("phase0 is ready; capturing screenshot...")
        output = capture_simulator_screenshot(output_dir / output_name, window_session)
        _print_status(f"Saved {output}")
        return output
    finally:
        if loader is not None:
            stop_watch_face_loader(loader)


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
    selected = validate_scenarios(
        scenarios, supported_devices(manifest), selected_names
    )
    if not selected:
        return []
    require_capture_tools()
    require_x11_display()
    sdk_dir = sdk_dir or connect_iq_sdk_dir()
    existing_window_ids = frozenset(list_windows())
    window_session: WindowSession | None = None
    simulator: Simulator | None = None
    try:
        _print_status("Starting Connect IQ Simulator...")
        simulator = start_simulator(
            sdk_dir / "bin" / "connectiq",
            env_overrides={"GDK_BACKEND": "x11"},
            cwd=REPO_DIR,
        )
        window_session = WindowSession(
            find_simulator_window(excluded_ids=existing_window_ids), set()
        )
        window_session.owned_ids.add(window_session.simulator_id)
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
                            window_session=window_session,
                            night_mode=night_mode,
                        )
                    )
            return outputs
        finally:
            try:
                close_simulator_windows(window_session.owned_ids)
            finally:
                stop_simulator(simulator)
    finally:
        if simulator is not None and window_session is None:
            stop_simulator(simulator)
        _restore_default_settings(make, build_dir)
