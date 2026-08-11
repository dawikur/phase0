# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from pathlib import Path


def source(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def test_clock_uses_the_same_centered_start_for_full_and_partial_updates() -> None:
    clock = source("source/widgets/base/clock.mc")

    assert "self.render_(_dc, self.clockStartX_(), self.time_, self.shade_);" in clock
    assert 'self.render_(_dc, self.clockStartX_(), self.time_, "");' in clock
    assert "var pos_x = self.clockStartX_() + offset_x;" in clock
    assert "self.centerX() -" in clock


def test_cached_widgets_only_become_dirty_when_rendered_state_changes() -> None:
    weather = source("source/widgets/text/weather.mc")
    am_pm = source("source/widgets/base/am_pm.mc")
    dawn_dusk = source("source/widgets/base/dawn_dusk.mc")

    assert "previous_value != self.value_" in weather
    assert "previous_is_small != self.is_small_" in weather

    assert "self.label_ != label" in am_pm
    assert "self.fallback_ != fallback" in am_pm
    assert "self.mode_ != mode" in am_pm

    assert "previous_dawn != self.dawn_" in dawn_dusk
    assert "previous_dusk != self.dusk_" in dawn_dusk
    assert "previous_moon_phase != self.moon_phase_" in dawn_dusk
    assert "previous_value_mode != self.value_mode_" in dawn_dusk
