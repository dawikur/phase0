# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>
# These tests exercise private orchestration helpers and import the module locally
# where needed to make their intent and patch targets explicit.
# pylint: disable=import-outside-toplevel,protected-access

import json
import re
from io import StringIO
from pathlib import Path
from threading import Event
from types import SimpleNamespace
from typing import Literal, cast
from unittest.mock import MagicMock, call, patch

import pytest
from PIL import Image

from scripts.utils.smoke import Simulator, SmokeSignals, WatchFaceLoader
from scripts.utils.store_screenshots import (
    Scenario,
    WindowSession,
    _wait_for_window,
    _xdotool,
    apply_property_overrides,
    capture_simulator_screenshot,
    clear_build_artifacts,
    close_simulator_windows,
    find_simulator_window,
    generate_screenshots,
    require_capture_tools,
    require_x11_display,
    run_scenario,
    validate_scenarios,
)


def generated_settings_document(**defaults: int | bool) -> dict[str, object]:
    return {
        "settings": [
            {
                "group": {
                    "entries": [
                        {"key": key, "defaultValue": value}
                        for key, value in defaults.items()
                    ]
                }
            }
        ],
        "supportsLiveValidation": False,
        "languages": [],
    }


def test_validate_scenarios_selects_in_config_order() -> None:
    scenarios = [
        Scenario("second", "fr255", {}),
        Scenario("first", "fenix7x", {}),
    ]

    selected = validate_scenarios(scenarios, ["fr255", "fenix7x"], ["first"])

    assert selected == [scenarios[1]]


def test_validate_scenarios_defaults_to_all() -> None:
    scenarios = [Scenario("first", "fr255", {}), Scenario("second", "fr255", {})]

    assert validate_scenarios(scenarios, ["fr255"]) == scenarios


@pytest.mark.parametrize(
    ("scenarios", "devices", "selected", "message"),
    [
        ([Scenario("bad name", "fr255", {})], ["fr255"], None, "Invalid"),
        (
            [Scenario("same", "fr255", {}), Scenario("same", "fr255", {})],
            ["fr255"],
            None,
            "Duplicate",
        ),
        ([Scenario("unknown", "venu3", {})], ["fr255"], None, "unsupported"),
        (
            [
                Scenario(
                    "bad-time",
                    "fr255",
                    {},
                    time_display=cast(Literal["12h", "24h"], "13h"),
                )
            ],
            ["fr255"],
            None,
            "unsupported time display",
        ),
        (
            [
                Scenario(
                    "bad-units",
                    "fr255",
                    {},
                    units_display=cast(Literal["metric", "statute"], "nautical"),
                )
            ],
            ["fr255"],
            None,
            "unsupported units display",
        ),
        ([Scenario("valid", "fr255", {})], ["fr255"], ["missing"], "Unknown"),
    ],
)
def test_validate_scenarios_rejects_invalid_configuration(
    scenarios: list[Scenario],
    devices: list[str],
    selected: list[str] | None,
    message: str,
) -> None:
    with pytest.raises(ValueError, match=message):
        validate_scenarios(scenarios, devices, selected)


def test_apply_property_overrides_updates_generated_settings(tmp_path: Path) -> None:
    settings = tmp_path / "settings.json"
    settings.write_text(
        json.dumps(generated_settings_document(GeneralAccent=1, ClockHeight=2)),
        encoding="utf-8",
    )

    apply_property_overrides(settings, {"GeneralAccent": 0x00AAAA})

    actual = json.loads(settings.read_text(encoding="utf-8"))
    entries = actual["settings"][0]["group"]["entries"]
    assert [entry["defaultValue"] for entry in entries] == [0x00AAAA, 2]


def test_apply_property_overrides_rejects_unknown_key_without_writing(
    tmp_path: Path,
) -> None:
    settings = tmp_path / "settings.json"
    original = json.dumps(generated_settings_document(GeneralAccent=1)) + "\n"
    settings.write_text(original, encoding="utf-8")

    with pytest.raises(ValueError, match="Unknown setting property"):
        apply_property_overrides(settings, {"Missing": 3})

    assert settings.read_text(encoding="utf-8") == original


def test_apply_property_overrides_rejects_wrong_type(tmp_path: Path) -> None:
    settings = tmp_path / "settings.json"
    settings.write_text(
        json.dumps(generated_settings_document(GeneralAccent=1)), encoding="utf-8"
    )

    with pytest.raises(ValueError, match="expects int, got bool"):
        apply_property_overrides(settings, {"GeneralAccent": True})


def test_apply_property_overrides_rejects_non_object(tmp_path: Path) -> None:
    settings = tmp_path / "settings.json"
    settings.write_text("[]\n", encoding="utf-8")

    with pytest.raises(ValueError, match="Expected a JSON object"):
        apply_property_overrides(settings, {})


def test_apply_property_overrides_rejects_missing_settings_list(
    tmp_path: Path,
) -> None:
    settings = tmp_path / "settings.json"
    settings.write_text("{}\n", encoding="utf-8")

    with pytest.raises(ValueError, match="Expected a settings list"):
        apply_property_overrides(settings, {})


@pytest.mark.parametrize(
    "section",
    [3, {}, {"group": 3}, {"group": {"entries": None}}],
)
def test_apply_property_overrides_skips_non_setting_sections(
    tmp_path: Path, section: object
) -> None:
    settings = tmp_path / "settings.json"
    settings.write_text(json.dumps({"settings": [section]}), encoding="utf-8")

    apply_property_overrides(settings, {})

    assert json.loads(settings.read_text(encoding="utf-8"))["settings"] == [section]


def test_clear_build_artifacts_preserves_store_outputs(tmp_path: Path) -> None:
    build = tmp_path / "build"
    store = build / "store"
    store.mkdir(parents=True)
    generated = [
        build / "phase0-fr255s_release.prg",
        build / "phase0-fr255s_release-settings.json",
        build / "phase0-fr255s_release.iq",
        build / ".settings.stamp",
    ]
    for path in generated:
        path.write_text("artifact", encoding="utf-8")
    screenshot = store / "compact.png"
    screenshot.write_bytes(b"png")

    clear_build_artifacts(build, "phase0", "fr255s")

    assert not any(path.exists() for path in generated)
    assert screenshot.read_bytes() == b"png"


def test_restore_default_settings_regenerates_without_scenario_overrides(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    build = tmp_path / "build"
    build.mkdir()
    stamp = build / ".settings.stamp"
    stamp.touch()
    monkeypatch.setattr(screenshots, "REPO_DIR", tmp_path)
    monkeypatch.setenv("PHASE0_STORE_SCREENSHOT_OVERRIDES", "{}")

    with patch("scripts.utils.store_screenshots.subprocess.run") as run:
        screenshots._restore_default_settings("make", build)

    assert not stamp.exists()
    run.assert_called_once()
    assert run.call_args.args[0] == ["make", "build/.settings.stamp"]
    assert "PHASE0_STORE_SCREENSHOT_OVERRIDES" not in run.call_args.kwargs["env"]


def test_run_scenario_builds_waits_captures_and_stops(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    scenario = Scenario(
        "preview", "fr255", {}, time_display="12h", units_display="statute"
    )
    simulator = Simulator(MagicMock(), SmokeSignals(Event()), MagicMock())
    loader = WatchFaceLoader(MagicMock(), MagicMock())
    settings = tmp_path / "settings.json"
    settings.touch()
    build = tmp_path / "build"
    output = tmp_path / "store" / "preview.png"
    events: list[str] = []
    ready_events: list[Event | None] = []

    monkeypatch.setattr(
        screenshots, "_build_scenario", lambda *args, **kwargs: settings
    )

    def start_watch_face(*_args: object, **kwargs: object) -> WatchFaceLoader:
        assert kwargs["program"] == build / "phase0-fr255_release.prg"
        return loader

    monkeypatch.setattr(screenshots, "_start_watch_face", start_watch_face)

    def wait_for_watch_face(sim: Simulator, _device: str) -> None:
        ready_events.append(sim.signals.ready)
        events.append("ready")

    monkeypatch.setattr(screenshots, "wait_for_watch_face", wait_for_watch_face)
    monkeypatch.setattr(
        screenshots,
        "set_simulator_display_settings",
        lambda time_display, units_display, _window_id: events.append(
            f"display:{time_display}:{units_display}"
        ),
    )
    monkeypatch.setattr(
        screenshots,
        "reset_simulator_app_data",
        lambda _window_id: events.append("reset"),
    )
    monkeypatch.setattr(screenshots, "check_simulator", lambda *_: None)
    monkeypatch.setattr(
        screenshots,
        "capture_simulator_screenshot",
        lambda path, _session: events.append("capture") or path,
    )
    monkeypatch.setattr(
        screenshots,
        "stop_watch_face_loader",
        lambda _loader: events.append("stop-app"),
    )
    result = run_scenario(
        scenario,
        make="make",
        name="phase0",
        build_dir=build,
        sdk_dir=tmp_path / "sdk",
        output_dir=tmp_path / "store",
        simulator=simulator,
        window_session=WindowSession("0x2", {"0x2"}),
    )

    assert result == output
    assert events == [
        "ready",
        "display:12h:statute",
        "reset",
        "ready",
        "capture",
        "stop-app",
    ]
    assert ready_events[0] is not ready_events[1]


def test_run_scenario_leaves_shared_simulator_running_if_app_fails_to_start(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    simulator = Simulator(MagicMock(), SmokeSignals(Event()), MagicMock())
    monkeypatch.setattr(
        screenshots, "_build_scenario", lambda *args, **kwargs: tmp_path
    )
    monkeypatch.setattr(
        screenshots,
        "_start_watch_face",
        MagicMock(side_effect=RuntimeError("launch failed")),
    )
    with pytest.raises(RuntimeError, match="launch failed"):
        run_scenario(
            Scenario("preview", "fr255", {}),
            make="make",
            name="phase0",
            build_dir=tmp_path / "build",
            sdk_dir=tmp_path / "sdk",
            output_dir=tmp_path / "store",
            simulator=simulator,
            window_session=WindowSession("0x2", {"0x2"}),
        )


def test_require_capture_tools_reports_missing_tools(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots.shutil, "which", lambda command: None)
    with pytest.raises(RuntimeError, match="wmctrl, xdotool"):
        require_capture_tools()


def test_require_capture_tools_accepts_available_tools(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots.shutil, "which", lambda command: f"/bin/{command}")
    require_capture_tools()


def test_print_status_uses_bold_for_terminal_output() -> None:
    import scripts.utils.store_screenshots as screenshots

    class TerminalOutput(StringIO):
        def isatty(self) -> bool:
            return True

    terminal = TerminalOutput()
    with patch.object(screenshots.sys, "stdout", terminal):
        screenshots._print_status("Ready")

    assert terminal.getvalue() == "\033[1mReady\033[0m\n"


@pytest.mark.parametrize(
    ("returncode", "stderr", "message"),
    [
        (0, "", None),
        (1, "display unavailable", "display unavailable"),
        (1, "", "needs X11"),
    ],
)
def test_require_x11_display(returncode: int, stderr: str, message: str | None) -> None:
    with patch(
        "scripts.utils.store_screenshots.subprocess.run",
        return_value=SimpleNamespace(returncode=returncode, stderr=stderr),
    ):
        if message is None:
            require_x11_display()
        else:
            with pytest.raises(RuntimeError, match=message):
                require_x11_display()


def test_find_simulator_window_returns_matching_window() -> None:
    result = SimpleNamespace(
        stdout="0x1 0 0 0 Other Window\n0x2 0 0 0 Connect IQ Device Simulator\n",
    )
    with patch("scripts.utils.store_screenshots.subprocess.run", return_value=result):
        assert find_simulator_window(timeout=1) == "0x2"


def test_find_simulator_window_matches_ciq_title() -> None:
    result = SimpleNamespace(
        stdout="0x2 0 0 0 CIQ Simulator - fenix 7X / tactix 7 / quatix 7X Solar\n",
    )
    with patch("scripts.utils.store_screenshots.subprocess.run", return_value=result):
        assert find_simulator_window(timeout=1) == "0x2"


def test_find_simulator_window_rejects_multiple_windows() -> None:
    result = SimpleNamespace(
        stdout=(
            "0x1 0 0 0 Connect IQ Device Simulator\n"
            "0x2 0 0 0 Connect IQ Device Simulator - fenix7x\n"
        ),
    )
    with patch("scripts.utils.store_screenshots.subprocess.run", return_value=result):
        with pytest.raises(RuntimeError, match="More than one"):
            find_simulator_window(timeout=1)


def test_find_simulator_window_excludes_existing_simulator() -> None:
    result = SimpleNamespace(
        stdout=(
            "0x1 0 0 0 CIQ Simulator - existing\n"
            "0x2 0 0 0 CIQ Simulator - screenshot run\n"
        ),
    )
    with patch("scripts.utils.store_screenshots.subprocess.run", return_value=result):
        assert (
            find_simulator_window(timeout=1, excluded_ids=frozenset({"0x1"})) == "0x2"
        )


def test_find_simulator_window_times_out(monkeypatch: pytest.MonkeyPatch) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots.time, "monotonic", MagicMock(side_effect=[0, 0, 1]))
    monkeypatch.setattr(screenshots.time, "sleep", lambda _: None)
    with patch(
        "scripts.utils.store_screenshots.subprocess.run",
        return_value=SimpleNamespace(stdout="0x1 0 0 0 Other Window\n"),
    ):
        with pytest.raises(RuntimeError, match="Timed out"):
            find_simulator_window(timeout=0.5)


def test_close_simulator_windows_closes_dialog_then_simulator() -> None:
    initial_windows = SimpleNamespace(
        stdout=(
            "0x1 0 0 0 Save Screen Capture\n" "0x2 0 0 0 CIQ Simulator - fenix 7X\n"
        )
    )
    no_windows = SimpleNamespace(stdout="")
    remaining_windows = SimpleNamespace(stdout="0x2 0 0 0 CIQ Simulator - fenix 7X\n")
    with patch(
        "scripts.utils.store_screenshots.subprocess.run",
        side_effect=[
            initial_windows,
            SimpleNamespace(),
            SimpleNamespace(),
            remaining_windows,
            no_windows,
        ],
    ) as run:
        close_simulator_windows({"0x1", "0x2"})

    assert [call.args[0] for call in run.call_args_list] == [
        ["wmctrl", "-l"],
        ["wmctrl", "-ic", "0x1"],
        ["wmctrl", "-ic", "0x2"],
        ["wmctrl", "-l"],
        ["wmctrl", "-l"],
    ]


def test_close_simulator_windows_returns_when_none_are_open() -> None:
    with patch(
        "scripts.utils.store_screenshots.subprocess.run",
        return_value=SimpleNamespace(stdout="0x1 0 0 0 Other Window\n"),
    ) as run:
        close_simulator_windows({"0x2"})

    run.assert_called_once_with(
        ["wmctrl", "-l"], capture_output=True, text=True, check=True
    )


def test_close_simulator_windows_keeps_unowned_windows() -> None:
    windows = SimpleNamespace(
        stdout=(
            "0x1 0 0 0 Save As\n"
            "0x2 0 0 0 CIQ Simulator - screenshot run\n"
            "0x3 0 0 0 CIQ Simulator - existing\n"
        )
    )
    remaining = SimpleNamespace(stdout="0x1 0 0 0 Save As\n0x3 0 0 0 CIQ Simulator\n")
    with patch(
        "scripts.utils.store_screenshots.subprocess.run",
        side_effect=[windows, SimpleNamespace(), remaining],
    ) as run:
        close_simulator_windows({"0x2"})

    assert [call.args[0] for call in run.call_args_list] == [
        ["wmctrl", "-l"],
        ["wmctrl", "-ic", "0x2"],
        ["wmctrl", "-l"],
    ]


def test_close_simulator_windows_reports_timeout() -> None:
    with patch(
        "scripts.utils.store_screenshots.subprocess.run",
        side_effect=[
            SimpleNamespace(stdout="0x2 0 0 0 CIQ Simulator\n"),
            SimpleNamespace(),
        ],
    ), pytest.raises(
        RuntimeError, match="waiting for the Connect IQ Simulator to close"
    ):
        close_simulator_windows({"0x2"}, timeout=-1)


def test_wait_for_window_returns_matching_dialog() -> None:
    result = SimpleNamespace(
        stdout="0x1 0 0 0 Other Window\n0x2 0 0 0 Save Screen Capture\n",
    )
    with patch("scripts.utils.store_screenshots.subprocess.run", return_value=result):
        assert (
            _wait_for_window(
                re.compile(
                    r"save (?:screenshot|screen capture)|save as", re.IGNORECASE
                ),
                1,
            )
            == "0x2"
        )


def test_wait_for_window_times_out(monkeypatch: pytest.MonkeyPatch) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots.time, "monotonic", MagicMock(side_effect=[0, 0, 1]))
    monkeypatch.setattr(screenshots.time, "sleep", lambda _: None)
    with patch(
        "scripts.utils.store_screenshots.subprocess.run",
        return_value=SimpleNamespace(stdout="0x1 0 0 0 Other Window\n"),
    ):
        assert _wait_for_window(re.compile("Save Screenshot"), 0.5) is None


def test_xdotool_runs_requested_command() -> None:
    with patch("scripts.utils.store_screenshots.subprocess.run") as run:
        _xdotool("key", "Return")

    run.assert_called_once_with(["xdotool", "key", "Return"], check=True)


def test_reset_simulator_app_data_uses_reset_all_app_data_menu(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    import scripts.utils.store_screenshots as screenshots

    commands: list[tuple[str, ...]] = []
    monkeypatch.setattr(screenshots, "find_simulator_window", lambda: "0x2")
    monkeypatch.setattr(
        screenshots.subprocess,
        "run",
        lambda command, **_kwargs: commands.append(tuple(command)),
    )
    monkeypatch.setattr(screenshots, "_xdotool", lambda *args: commands.append(args))
    monkeypatch.setattr(screenshots.time, "sleep", lambda _delay: None)

    screenshots.reset_simulator_app_data()

    assert commands == [
        ("wmctrl", "-ia", "0x2"),
        ("key", "--clearmodifiers", "alt+f"),
        ("key", "--clearmodifiers", "r"),
        ("key", "--clearmodifiers", "r"),
        ("key", "--clearmodifiers", "Return"),
    ]


@pytest.mark.parametrize(
    ("time_display", "units_display", "time_down", "units_down"),
    [("12h", "metric", 0, 0), ("24h", "statute", 1, 1)],
)
def test_set_simulator_display_settings_uses_settings_menu(
    time_display: Literal["12h", "24h"],
    units_display: Literal["metric", "statute"],
    time_down: int,
    units_down: int,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    import scripts.utils.store_screenshots as screenshots

    commands: list[tuple[str, ...]] = []
    monkeypatch.setattr(screenshots, "find_simulator_window", lambda: "0x2")
    monkeypatch.setattr(
        screenshots.subprocess,
        "run",
        lambda command, **_kwargs: commands.append(tuple(command)),
    )
    monkeypatch.setattr(screenshots, "_xdotool", lambda *args: commands.append(args))
    monkeypatch.setattr(screenshots.time, "sleep", lambda _delay: None)

    screenshots.set_simulator_display_settings(time_display, units_display)

    assert commands == [
        ("wmctrl", "-ia", "0x2"),
        ("key", "--clearmodifiers", "alt+s"),
        ("key", "Home"),
        ("key", "Right"),
        ("key", "Home"),
        *[("key", "Down")] * time_down,
        ("key", "Return"),
        ("key", "--clearmodifiers", "alt+s"),
        ("key", "Home"),
        ("key", "Down"),
        ("key", "Right"),
        ("key", "Home"),
        *[("key", "Down")] * units_down,
        ("key", "Return"),
    ]


def test_force_night_mode_rejects_missing_function_without_changing_source(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    source = tmp_path / "view.mc"
    source.write_text("class View {}\n", encoding="utf-8")
    monkeypatch.setattr(screenshots, "VIEW_SOURCE", source)

    with pytest.raises(RuntimeError, match="Could not locate isNightMode_"):
        with screenshots.force_night_mode(True):
            pytest.fail("Night mode should not be entered")

    assert source.read_text(encoding="utf-8") == "class View {}\n"


def test_capture_simulator_screenshot_saves_valid_native_image(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    output = tmp_path / "store" / "preview.png"
    commands: list[tuple[str, ...]] = []
    typed_path: list[str] = []
    xdotool_commands: list[tuple[str, ...]] = []
    save_confirmations = 0
    file_write_attempts = 0
    session = WindowSession("0x2", {"0x2"})
    excluded_ids: list[frozenset[str]] = []
    monkeypatch.setattr(screenshots, "REPO_DIR", tmp_path)
    monkeypatch.setattr(
        screenshots,
        "list_windows",
        lambda: {"0x2": "CIQ Simulator", "0x9": "Unrelated Save As"},
    )

    def wait_for_dialog(*_args: object, **kwargs: object) -> str:
        excluded_ids.append(cast(frozenset[str], kwargs["excluded_ids"]))
        return "0x3"

    monkeypatch.setattr(screenshots, "_wait_for_window", wait_for_dialog)

    def delayed_file(_delay: float) -> None:
        nonlocal file_write_attempts
        if typed_path and save_confirmations >= 2:
            file_write_attempts += 1
            destination = tmp_path / typed_path[0]
            if file_write_attempts == 1:
                destination.write_bytes(b"partial PNG")
            else:
                Image.new("RGB", (240, 240), "black").save(destination)

    monkeypatch.setattr(screenshots.time, "sleep", delayed_file)
    monkeypatch.setattr(
        screenshots.subprocess,
        "run",
        lambda command, **kwargs: commands.append(tuple(command)),
    )

    def fake_xdotool(*arguments: str) -> None:
        nonlocal save_confirmations
        xdotool_commands.append(arguments)
        if arguments[0] == "type":
            typed_path.append(arguments[-1])
        if typed_path and arguments[0] == "key" and arguments[-1] == "Return":
            save_confirmations += 1

    monkeypatch.setattr(screenshots, "_xdotool", fake_xdotool)

    assert capture_simulator_screenshot(output, session) == output
    with Image.open(output) as image:
        assert image.size == (240, 240)
    assert commands == [
        ("wmctrl", "-ia", "0x2"),
        ("wmctrl", "-ia", "0x3"),
    ]
    assert typed_path and "/" not in typed_path[0]
    assert ("key", "--clearmodifiers", "Return") in xdotool_commands
    assert file_write_attempts >= 2
    assert session.owned_ids == {"0x2", "0x3"}
    assert excluded_ids == [frozenset({"0x2", "0x9"})] * 2
    assert not list(tmp_path.glob("phase0-store-shot-*.png"))


def test_capture_simulator_screenshot_reports_missing_dialog(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots, "find_simulator_window", lambda: "0x2")
    monkeypatch.setattr(screenshots, "_wait_for_window", lambda *_, **__: None)
    monkeypatch.setattr(screenshots.time, "sleep", lambda _: None)
    monkeypatch.setattr(screenshots, "_xdotool", lambda *_: None)
    monkeypatch.setattr(screenshots.subprocess, "run", lambda *_args, **_kwargs: None)

    with pytest.raises(RuntimeError, match="Save Screenshot dialog"):
        capture_simulator_screenshot(tmp_path / "preview.png")


def test_capture_simulator_screenshot_reports_missing_file(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots, "SCREENSHOT_FILE_TIMEOUT", 0)
    monkeypatch.setattr(screenshots, "find_simulator_window", lambda: "0x2")
    monkeypatch.setattr(screenshots, "_wait_for_window", lambda *_, **__: "0x3")
    monkeypatch.setattr(screenshots.time, "sleep", lambda _: None)
    monkeypatch.setattr(screenshots, "_xdotool", lambda *_: None)
    monkeypatch.setattr(screenshots.subprocess, "run", lambda *_args, **_kwargs: None)

    with pytest.raises(RuntimeError, match="did not create"):
        capture_simulator_screenshot(tmp_path / "preview.png")


def test_capture_simulator_screenshot_reports_invalid_image(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots, "SCREENSHOT_FILE_TIMEOUT", 0)
    monkeypatch.setattr(screenshots, "REPO_DIR", tmp_path)
    monkeypatch.setattr(screenshots, "find_simulator_window", lambda: "0x2")
    monkeypatch.setattr(screenshots, "_wait_for_window", lambda *_, **__: "0x3")
    monkeypatch.setattr(screenshots.time, "sleep", lambda _: None)
    monkeypatch.setattr(screenshots.subprocess, "run", lambda *_args, **_kwargs: None)

    def fake_xdotool(*arguments: str) -> None:
        if arguments[0] == "type":
            (tmp_path / arguments[-1]).write_text("not an image", encoding="utf-8")

    monkeypatch.setattr(screenshots, "_xdotool", fake_xdotool)

    with pytest.raises(RuntimeError, match="not a valid image"):
        capture_simulator_screenshot(tmp_path / "preview.png")


def test_build_scenario_builds_and_overrides_settings(tmp_path: Path) -> None:
    import scripts.utils.store_screenshots as screenshots

    scenario = Scenario("preview", "fr255", {"GeneralAccent": 10})
    build = tmp_path / "build"
    build.mkdir()
    settings = build / "phase0-fr255_release-settings.json"
    settings.write_text(
        json.dumps(generated_settings_document(GeneralAccent=1)), encoding="utf-8"
    )

    def fake_build(*_args: object, **_kwargs: object) -> None:
        settings.write_text(
            json.dumps(generated_settings_document(GeneralAccent=1)), encoding="utf-8"
        )

    with patch("scripts.utils.store_screenshots.subprocess.run") as run:
        run.side_effect = fake_build
        result = screenshots._build_scenario(
            scenario, make="make", name="phase0", build_dir=build
        )

    assert result == settings
    result_settings = json.loads(settings.read_text(encoding="utf-8"))
    assert result_settings["settings"][0]["group"]["entries"][0]["defaultValue"] == 10
    assert run.call_args.args[0] == [
        "make",
        "build_release",
        "NAME=phase0",
        "DEVICE=fr255",
        "CHANNEL=release",
    ]
    assert run.call_args.kwargs["cwd"] == screenshots.REPO_DIR
    assert run.call_args.kwargs["check"] is True
    assert (
        json.loads(run.call_args.kwargs["env"]["PHASE0_STORE_SCREENSHOT_OVERRIDES"])
        == scenario.properties
    )


def test_build_scenario_reports_missing_settings_file(
    tmp_path: Path,
) -> None:
    import scripts.utils.store_screenshots as screenshots

    with patch("scripts.utils.store_screenshots.subprocess.run"):
        with pytest.raises(RuntimeError, match="did not produce settings file"):
            screenshots._build_scenario(
                Scenario("preview", "fr255", {}),
                make="make",
                name="phase0",
                build_dir=tmp_path,
            )


def test_start_watch_face_passes_scenario_settings(
    tmp_path: Path,
) -> None:
    import scripts.utils.store_screenshots as screenshots

    process = MagicMock()
    thread = MagicMock()
    signals = SmokeSignals(Event())
    settings = tmp_path / "phase0-fr255_release-settings.json"
    program = tmp_path / "build" / "phase0-preview-123.prg"
    with patch(
        "scripts.utils.store_screenshots.start_logged_process",
        return_value=(process, thread),
    ) as start:
        loader = screenshots._start_watch_face(
            tmp_path / "sdk" / "monkeydo",
            scenario=Scenario("preview", "fr255", {}),
            settings=settings,
            signals=signals,
            program=program,
        )

    assert loader == WatchFaceLoader(process, thread)
    start.assert_called_once_with(
        [
            str(tmp_path / "sdk" / "monkeydo"),
            str(program),
            "fr255",
            "-a",
            f"{settings}:GARMIN/Settings/PHASE0-PREVIEW-123-settings.json",
        ],
        signals,
    )


def test_generate_screenshots_runs_selected_scenarios(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    scenarios = [Scenario("first", "fr255", {}), Scenario("second", "fenix7x", {})]
    monkeypatch.setattr(
        screenshots, "supported_devices", lambda _: ["fr255", "fenix7x"]
    )
    monkeypatch.setattr(screenshots, "require_capture_tools", lambda: None)
    monkeypatch.setattr(screenshots, "require_x11_display", lambda: None)
    monkeypatch.setattr(screenshots, "connect_iq_sdk_dir", lambda: tmp_path / "sdk")
    simulator = Simulator(MagicMock(), SmokeSignals(Event()), MagicMock())
    start_simulator = MagicMock(return_value=simulator)
    monkeypatch.setattr(screenshots, "start_simulator", start_simulator)
    monkeypatch.setattr(screenshots, "list_windows", lambda: {})
    monkeypatch.setattr(screenshots, "find_simulator_window", lambda **_kwargs: "0x2")
    monkeypatch.setattr(screenshots, "close_simulator_windows", lambda _owned: None)
    stop_simulator = MagicMock()
    monkeypatch.setattr(screenshots, "stop_simulator", stop_simulator)
    run = MagicMock(
        side_effect=lambda scenario, **kwargs: kwargs["output_dir"]
        / (
            f"{scenario.name}-aod.png"
            if kwargs["night_mode"]
            else f"{scenario.name}.png"
        )
    )
    monkeypatch.setattr(screenshots, "run_scenario", run)

    outputs = generate_screenshots(
        scenarios,
        manifest=tmp_path / "manifest.xml",
        make="make",
        name="phase0",
        build_dir=tmp_path / "build",
        sdk_dir=None,
        output_dir=tmp_path / "store",
        selected_names=["second"],
    )

    assert outputs == [
        tmp_path / "store" / "second.png",
        tmp_path / "store" / "second-aod.png",
    ]
    start_simulator.assert_called_once_with(
        tmp_path / "sdk" / "bin" / "connectiq",
        env_overrides={"GDK_BACKEND": "x11"},
        cwd=screenshots.REPO_DIR,
    )
    stop_simulator.assert_called_once_with(simulator)
    assert run.call_args_list == [
        call(
            scenarios[1],
            make="make",
            name="phase0",
            build_dir=tmp_path / "build",
            sdk_dir=tmp_path / "sdk",
            output_dir=tmp_path / "store",
            simulator=simulator,
            window_session=WindowSession("0x2", {"0x2"}),
            night_mode=False,
        ),
        call(
            scenarios[1],
            make="make",
            name="phase0",
            build_dir=tmp_path / "build",
            sdk_dir=tmp_path / "sdk",
            output_dir=tmp_path / "store",
            simulator=simulator,
            window_session=WindowSession("0x2", {"0x2"}),
            night_mode=True,
        ),
    ]


def test_generate_screenshots_returns_when_no_scenarios_selected(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots, "supported_devices", lambda _: [])
    assert not generate_screenshots(
        [],
        manifest=tmp_path / "manifest.xml",
        make="make",
        name="phase0",
        build_dir=tmp_path / "build",
        sdk_dir=None,
        output_dir=tmp_path / "store",
    )


def test_generate_screenshots_stops_simulator_if_window_does_not_appear(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    simulator = Simulator(MagicMock(), SmokeSignals(Event()), MagicMock())
    monkeypatch.setattr(screenshots, "supported_devices", lambda _: ["fr255"])
    monkeypatch.setattr(screenshots, "require_capture_tools", lambda: None)
    monkeypatch.setattr(screenshots, "require_x11_display", lambda: None)
    monkeypatch.setattr(screenshots, "list_windows", lambda: {})
    monkeypatch.setattr(screenshots, "start_simulator", lambda *_, **__: simulator)
    monkeypatch.setattr(
        screenshots,
        "find_simulator_window",
        MagicMock(side_effect=RuntimeError("window missing")),
    )
    stop = MagicMock()
    monkeypatch.setattr(screenshots, "stop_simulator", stop)
    monkeypatch.setattr(screenshots, "_restore_default_settings", lambda *_: None)

    with pytest.raises(RuntimeError, match="window missing"):
        generate_screenshots(
            [Scenario("preview", "fr255", {})],
            manifest=tmp_path / "manifest.xml",
            make="make",
            name="phase0",
            build_dir=tmp_path / "build",
            sdk_dir=tmp_path / "sdk",
            output_dir=tmp_path / "store",
        )

    stop.assert_called_once_with(simulator)


def test_generate_screenshots_rejects_invalid_scenarios_before_x11(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    import scripts.utils.store_screenshots as screenshots

    monkeypatch.setattr(screenshots, "supported_devices", lambda _: ["fr255"])
    require_tools = MagicMock()
    monkeypatch.setattr(screenshots, "require_capture_tools", require_tools)

    with pytest.raises(ValueError, match="unsupported"):
        generate_screenshots(
            [Scenario("invalid", "fenix7x", {})],
            manifest=tmp_path / "manifest.xml",
            make="make",
            name="phase0",
            build_dir=tmp_path / "build",
            sdk_dir=tmp_path / "sdk",
            output_dir=tmp_path / "store",
        )

    require_tools.assert_not_called()
