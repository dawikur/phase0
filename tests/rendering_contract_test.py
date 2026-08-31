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


def test_time_refresh_preserves_the_last_rendered_value_for_partial_updates() -> None:
    clock = source("source/widgets/base/clock.mc")
    seconds = source("source/widgets/base/seconds.mc")

    assert "self.prepared_hour_ = Data.Units.convertHour(Runtime.clock.hour);" in clock
    assert "var previous_hour = self.rendered_hour_;" in clock
    assert "self.refresh(_dc);" not in clock.split("hidden function update_(", 1)[1]

    assert "self.prepared_second_ = Runtime.clock.sec;" in seconds
    assert "var previous_second = self.rendered_second_;" in seconds
    assert (
        "self.refresh(_dc);"
        not in seconds.split("function update(", 1)[1].split(
            "function updateMinimal", 1
        )[0]
    )


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


def test_show_invalidates_cached_calendar_state() -> None:
    view = source("source/phase0/view.mc")

    on_show = view.split("function onShow", 1)[1].split("function onHide", 1)[0]
    assert "self.invalidate_();" in on_show


def test_update_mode_preserves_partial_updates_until_the_budget_is_exhausted() -> None:
    view = source("source/phase0/view.mc")

    assert "static const UPDATE_MODE_HIGH_POWER = 0;" in view
    assert "static const UPDATE_MODE_LOW_POWER = 1;" in view
    assert "static const UPDATE_MODE_LIMITED_POWER = 2;" in view

    on_enter_sleep = view.split("function onEnterSleep", 1)[1].split(
        "function onExitSleep", 1
    )[0]
    on_exit_sleep = view.split("function onExitSleep", 1)[1].split(
        "function onSettingsChanged", 1
    )[0]
    budget_exceeded = view.split("function handlePowerBudgetExceeded", 1)[1].split(
        "function handlePress", 1
    )[0]

    assert "self.update_mode_ = UPDATE_MODE_LOW_POWER;" in on_enter_sleep
    assert "self.update_mode_ = UPDATE_MODE_HIGH_POWER;" in on_exit_sleep
    assert "self.update_mode_ = UPDATE_MODE_LIMITED_POWER;" in budget_exceeded
    assert view.count("self.update_mode_ != UPDATE_MODE_LIMITED_POWER") == 2


def test_weather_changes_refresh_dependent_widgets_outside_their_schedule() -> None:
    provider = source("source/utils/weather_provider.mc")
    data_base = source("source/data/base.mc")
    metric = source("source/widgets/metric.mc")
    gauge = source("source/widgets/gauge.mc")
    weather = source("source/widgets/text/weather.mc")
    view = source("source/phase0/view.mc")

    assert "var revision as Lang.Number = 0;" in provider
    assert "function setField_(" in provider
    assert "revision += 1;" in provider
    assert "function refreshRevision() as Lang.Number?" in data_base
    assert "function needsRefresh() as Lang.Boolean" in metric
    assert "function needsRefresh() as Lang.Boolean" in gauge
    assert "WeatherProvider.revision" in weather

    for path in (
        "source/data/feels_like_temperature.mc",
        "source/data/high_temperature.mc",
        "source/data/low_temperature.mc",
        "source/data/rain.mc",
        "source/data/relative_humidity.mc",
        "source/data/uv_index.mc",
        "source/data/wind.mc",
    ):
        weather_data = source(path)
        assert "Base.initialize(" in weather_data
        assert "function refreshRevision() as Lang.Number?" in weather_data

    refresh_position = view.index("self.refreshWidgets_(_dc, self.widgets_per_sec_);")
    changed_position = view.index("self.refreshChangedWidgets_", refresh_position)
    update_position = view.index("self.updateWidgets_(dc, self.widgets_per_hour_);")
    assert refresh_position < changed_position < update_position


def test_weather_refresh_recovers_after_the_clock_moves_backward() -> None:
    provider = source("source/utils/weather_provider.mc")

    refresh = provider.split("function refresh", 1)[1].split(
        "function nextRefreshSeconds_", 1
    )[0]
    assert "var last_observed_seconds_" in provider
    assert "observeTime_(now_seconds);" in refresh
    assert "if (_now_seconds < last_observed_seconds_)" in provider
    assert "function WeatherProviderClockRollbackTest(" in provider


def test_heart_rate_does_not_fall_back_to_the_persistent_sensor_cache() -> None:
    heart_rate = source("source/data/heart_rate.mc")

    refresh = heart_rate.split("function refresh", 1)[1]
    assert "self.value = null;" in refresh
    assert "SensorProvider.get(" not in refresh
    assert "SensorHistory.getHeartRateHistory(" in refresh
    assert "ActivityMonitor.INVALID_HR_SAMPLE" in refresh
