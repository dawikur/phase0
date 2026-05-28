// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;
import Toybox.WatchUi;

module Phase0 {

class View extends WatchUi.WatchFace {
	typedef Complications as Lang.Array<Complication.Base>;
	typedef Conditions as Lang.Array<Complication.Condition>;
	typedef Gauges as Lang.Array<Complication.Gauge>;
	typedef Metrics as Lang.Array<Complication.Metric>;

	// ==== fields ====

	// ---- base ----
	hidden var is_base_view_ as Lang.Boolean = true;
	hidden var is_high_power_ as Lang.Boolean = true;
	hidden var is_night_mode_ as Lang.Boolean = false;
	hidden var is_visible_ as Lang.Boolean = false;

	// ---- refresh ----
	hidden var last_refresh_min_ as Lang.Number = -1;
	hidden var last_refresh_hour_ as Lang.Number = -1;

	// ---- complications ----

	hidden const status_ = new Main.Status();

	hidden var clock_ as Main.Clock = new Main.Clock(false);
	hidden var seconds_ as Main.Seconds = new Main.Seconds(false);
	hidden var battery_ as Main.Battery = new Main.Battery();

	hidden var complications_per_min_ as Complications = [];
	hidden var complications_per_hour_ as Complications = [];

	hidden var metrics_base_ as Metrics = [];
	hidden var metrics_alt_ as Metrics = [];

	// ==== methods ====

	function initialize() {
		WatchFace.initialize();
	}

	function onShow() as Void {
		self.is_visible_ = true;
	}

	function onHide() as Void {
		self.is_visible_ = false;
	}

	function onEnterSleep() as Void {
		self.is_base_view_ = true;
		WatchUi.requestUpdate();
	}

	function onExitSleep() as Void {
		self.is_base_view_ = true;
		self.is_high_power_ = true;
		WatchUi.requestUpdate();
	}

	function onSettingsChanged() as Void {
		WatchUi.requestUpdate();
	}

	function onPowerBudgetExceeded() as Void {
		self.is_high_power_ = false;
	}

	function onPress(_click_event as WatchUi.ClickEvent) as Lang.Boolean {
		var coordinates = _click_event.getCoordinates();
		var pos_x = coordinates[0];
		var pos_y = coordinates[1];

		if (self.clock_.contains(pos_x, pos_y)) {
			self.is_base_view_ = ! self.is_base_view_;
			WatchUi.requestUpdate();

			return true;
		}

		if (self.battery_.contains(pos_x, pos_y)) {
			return self.battery_.open();
		}

		if (!self.is_night_mode_) {
			var complications_per_min_size = complications_per_min_.size();
			for (var i = 0; i < complications_per_min_size; ++i) {
				var complication = complications_per_min_[i];
				if (complication.contains(pos_x, pos_y)) {
					return complication.open();
				}
			}

			var complications_per_hour_size = complications_per_hour_.size();
			for (var i = 0; i < complications_per_hour_size; ++i) {
				var complication = complications_per_hour_[i];
				if (complication.contains(pos_x, pos_y)) {
					return complication.open();
				}
			}

			var metrics = self.getMetrics_();
			var metrics_size = metrics.size();
			for (var i = 0; i < metrics_size; ++i) {
				var metric = metrics[i];
				if (metric.contains(pos_x, pos_y)) {
					return metric.open();
				}
			}
		}

		return false;
	}

	function onLayout(_dc as Graphics.Dc) as Void {
		// ==== layout ====

		self.complications_per_min_ = [];
		self.complications_per_hour_ = [];

		var layout = new Layout(_dc);

		// ==== top outer ====

		var sun_moon = new Complication.SunMoon(layout.outer.small);
			sun_moon.pos_x = layout.outer.center_x;
			sun_moon.pos_y = layout.outer.pos_y;
			sun_moon.size_x = layout.outer.size_x;
			sun_moon.size_y = layout.outer.size_y;
		self.complications_per_hour_.add(sun_moon);

		// ==== top middle ====

		var conditions = [
			new Complication.Condition(_dc, new Data.Rain(), layout.middle.small),
			new Complication.Condition(_dc, new Data.Uv(), layout.middle.small),
			new Complication.Condition(_dc, new Data.Wind(), layout.middle.small),
		];
		self.reflowComplications_(conditions, layout.middle);

		self.complications_per_min_.addAll(conditions);

		// ==== top inner ====

		var weather = new Complication.Weather(layout.inner.small);
			weather.pos_x = layout.inner.center_x;
			weather.pos_y = layout.inner.center_y;
			weather.size_x = layout.inner.size_x;
			weather.size_y = layout.inner.size_y;
		self.complications_per_min_.add(weather);

		// ==== main ====

		var main_right = layout.rightBox(layout.left);

		self.status_.center_x = layout.left.center_x;
		self.status_.center_y = layout.left.center_y;

		self.clock_ = new Main.Clock(layout.clock.small);
		self.clock_.center_x = layout.clock.center_x;
		self.clock_.center_y = layout.clock.center_y;
		self.clock_.radius_x = layout.clock.radius_x;
		self.clock_.radius_y = layout.clock.radius_y;

		var gauges = [
			new Complication.Gauge(new Data.BodyBattery(), main_right.size_y),
			new Complication.Gauge(new Data.Stress(), main_right.size_y),
			new Complication.Gauge(new Data.Move(), main_right.size_y),
		];
		self.reflowComplications_(gauges, layout.rightBox(layout.left));

		self.complications_per_min_.addAll(gauges);

		// ==== bottom inner ====

		var bottom_inner = layout.bottomBox(layout.inner);

		var date_size_x = Render.textWidth(_dc, "ABC 00 XYZ", layout.inner.small);
		var date = new Complication.Date(layout.inner.small);
			date.pos_x = bottom_inner.pos_x;
			date.pos_y = bottom_inner.pos_y;
			date.size_x = date_size_x;
			date.size_y = bottom_inner.size_y;
		self.complications_per_hour_.add(date);

		var seconds_size_x = Render.textWidth(_dc, "00", bottom_inner.small);
		self.seconds_ = new Main.Seconds(layout.inner.small);
			self.seconds_.pos_x = bottom_inner.end_x - seconds_size_x;
			self.seconds_.pos_y = bottom_inner.pos_y;
			self.seconds_.size_x = seconds_size_x;
			self.seconds_.size_y = bottom_inner.size_y;

		if (!Data.Units.SETTINGS.is_24_hour) {
			var left_space_x =
				bottom_inner.size_x - date_size_x - seconds_size_x;
			var am_pm_size_x =
				Render.iconsWidth(_dc, Fonts.ICON_AM_PM_BEGIN) +
				Render.textWidth(_dc, "am", true) +
				Render.iconsWidth(_dc, Fonts.ICON_AM_PM_END);
			var am_pm_pos_x = bottom_inner.pos_x + date_size_x +
				(left_space_x - am_pm_size_x) / 2;

			if (left_space_x < am_pm_size_x) {
				var am_pm_icon_size_x = Render.iconsWidth(_dc, Fonts.ICON_DAWN);

				bottom_inner.small = true;
				am_pm_size_x = left_space_x <= 0 ? 0 :
					(left_space_x < am_pm_icon_size_x ? left_space_x : am_pm_icon_size_x);

				if (date_size_x <= seconds_size_x) {
					am_pm_pos_x = bottom_inner.pos_x + date_size_x;
				} else {
					am_pm_pos_x = bottom_inner.end_x - seconds_size_x - am_pm_size_x;
				}
			}

			var am_pm = new Complication.AmPm(bottom_inner.small);
				am_pm.pos_x = am_pm_pos_x;
				am_pm.pos_y = bottom_inner.pos_y;
				am_pm.size_x = am_pm_size_x;
				am_pm.size_y = bottom_inner.size_y;
			self.complications_per_hour_.add(am_pm);
		}

		// ==== bottom middle ====

		var bottom_middle = layout.bottomBox(layout.middle);

		// ---- metrics base ----

		var metrics_base_size_regular =
			self.metricWidth_(_dc, 3, Render.SIZE_REGULAR) * 3;
		var metrics_base_small = bottom_middle.small || (bottom_middle.size_x < metrics_base_size_regular);

		self.metrics_base_= [
			new Complication.Metric(_dc, new Data.HeartRate(), 3, metrics_base_small),
			new Complication.Metric(_dc, new Data.Steps(), 3, metrics_base_small),
			new Complication.Metric(_dc, new Data.FloorsClimbed(), 3, metrics_base_small),
		];
		self.reflowComplications_(self.metrics_base_, bottom_middle);

		// ---- metrics alt ----

		var metrics_alt_size_regular =
			self.metricWidth_(_dc, 5, Render.SIZE_REGULAR) +
			self.metricWidth_(_dc, 3, Render.SIZE_REGULAR);
		var metrics_alt_small = bottom_middle.small || (bottom_middle.size_x < metrics_alt_size_regular);

		self.metrics_alt_ = [
			new Complication.Metric(_dc, new Data.Calories(), 5, metrics_alt_small),
			new Complication.Metric(_dc, new Data.SolarIntensity(), 3, metrics_alt_small),
		];
		self.reflowComplications_(self.metrics_alt_, bottom_middle);

		// ==== bottom outer ====

		var bottom_outer = layout.bottomBox(layout.outer);

		self.battery_.pos_x = bottom_outer.pos_x;
		self.battery_.pos_y = bottom_outer.pos_y;
		self.battery_.size_x = bottom_outer.size_x;
		self.battery_.size_y = bottom_outer.size_y;
	}

	function onUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }

		// ==== update ====

		var clock = System.getClockTime();
		var metrics = self.getMetrics_();

		{
			self.status_.refresh(_dc);
			self.seconds_.refresh(_dc);

			self.refresh_(_dc, metrics);
		}

		if (self.last_refresh_min_ != clock.min) {
			self.last_refresh_min_ = clock.min;
			self.is_night_mode_ = self.isNightMode_();

			self.clock_.refresh(_dc);
			self.battery_.refresh(_dc);

			self.refresh_(_dc, self.complications_per_min_);
		}
		if (self.last_refresh_hour_ != clock.hour) {
			self.last_refresh_hour_ = clock.hour;

			self.refresh_(_dc, self.complications_per_hour_);
		}

		// ==== render ====

		_dc.clearClip();

		_dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		_dc.clear();

		if (self.is_night_mode_) {
			self.clock_.render(_dc, true);
			self.status_.render(_dc, true);

			self.battery_.render(_dc);
		} else {
			self.clock_.render(_dc, false);
			self.status_.render(_dc, false);

			self.seconds_.render(_dc, self.is_high_power_);

			self.battery_.render(_dc);

			self.render_(_dc, metrics);
			self.render_(_dc, self.complications_per_min_);
			self.render_(_dc, self.complications_per_hour_);
		}
	}

	function onPartialUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }
		if (self.is_night_mode_) { return; }
		if (!self.is_high_power_) { return; }

		self.seconds_.refresh(_dc);

		_dc.setClip(
			self.seconds_.pos_x, self.seconds_.pos_y,
			self.seconds_.size_x, self.seconds_.size_y
		);

		_dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		_dc.clear();

		self.seconds_.render(_dc, true);
	}

	hidden function isNightMode_() as Lang.Boolean {
		var user_profile = UserProfile.getProfile();
		if (user_profile.sleepTime == null) {
			return false;
		}
		if (user_profile.wakeTime == null) {
			return false;
		}

		var sleep_time = user_profile.sleepTime as Time.Duration;
		var wake_time = user_profile.wakeTime as Time.Duration;

		var now = Time.now();
        var midnight = Time.today();
        var since_midnight = now.subtract(midnight) as Time.Duration;

		if(sleep_time.greaterThan(wake_time)) {
			return
				!since_midnight.lessThan(sleep_time) or
				!since_midnight.greaterThan(wake_time);
		}
		return
			!since_midnight.lessThan(sleep_time) and
			!since_midnight.greaterThan(wake_time);
	}

	hidden function refresh_(
		_dc as Graphics.Dc,
		_complications as Complications or Metrics
	) as Void {
		var complications_size = _complications.size();
		for (var i = 0; i < complications_size; ++i) {
			_complications[i].refresh(_dc);
		}
	}

	hidden function render_(
		_dc as Graphics.Dc,
		_complications as Complications or Metrics
	) as Void {
		var complications_size = _complications.size();
		for (var i = 0; i < complications_size; ++i) {
			_complications[i].render(_dc);
		}
	}

	hidden function getMetrics_() as Metrics {
		if (self.metrics_alt_.size() == 0) {
			return self.metrics_base_;
		}

		return
			self.is_base_view_ ?
			self.metrics_base_ :
			self.metrics_alt_;
	}

	static hidden function reflowComplications_(
		_complications as Complications,
		_box as Box
	) as Void {
		var complications_size = _complications.size();

		var occupied_size_x = 0;
		for (var i = 0; i < complications_size; ++i) {
			occupied_size_x += _complications[i].size_x;
		}

		var spacing = (_box.size_x - occupied_size_x) / (2 * complications_size);

		var pos_x = _box.pos_x + spacing;
		var pos_y = _box.pos_y;
		for (var i = 0; i < complications_size; ++i) {
			var complication = _complications[i];

			complication.pos_x = pos_x;
			complication.pos_y = pos_y;

			pos_x += 2 * spacing + complication.size_x;
		}
	}

	hidden function metricWidth_(
		_dc as Graphics.Dc,
		_count as Lang.Number,
		_small as Lang.Boolean
	) as Lang.Number {
		return Render.numberWidth(_dc, _count, _small) + 3 * Render.SPACING;
	}
}

} // module Phase0
