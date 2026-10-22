# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>
# Import orchestration locally to keep monkeypatch targets explicit.
# pylint: disable=import-outside-toplevel

from pathlib import Path
from threading import Event
from unittest.mock import MagicMock, call

import pytest

from scripts.utils.smoke import Simulator, SmokeSignals
from scripts.utils.store_screenshots import (
    Scenario,
    WindowSession,
    generate_screenshots,
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
