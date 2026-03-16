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
	typedef Metrics as Lang.Array<Complication.Metric>;
	typedef Gauges as Lang.Array<Complication.Gauge>;
	typedef Conditions as Lang.Array<Complication.Condition>;

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

	hidden const clock_ = new Main.Clock();
	hidden const seconds_ = new Main.Seconds();
	hidden const battery_ = new Main.Battery();

	hidden var complications_per_min_ as Complications = [];
	hidden var complications_per_hour_ as Complications = [];

	hidden var metrics_base_ as Metrics = [];
	hidden var metrics_alt_ as Metrics = [];

	// ==== methods ====

	function initialize() {
		WatchFace.initialize();
	}

	function onShow() as Void {
		//self.is_base_view_ = true;
		self.is_visible_ = true;
	}

	function onHide() as Void {
		//self.is_base_view_ = true;
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

		var complications = [];
		complications.addAll(self.complications_per_min_);
		complications.addAll(self.complications_per_hour_);

		var complications_size = complications.size();
		for (var i = 0; i < complications_size; ++i) {
			var complication = complications[i];
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

		return false;
	}

	function onLayout(_dc as Graphics.Dc) as Void {
		// ==== complications ====

		self.complications_per_min_ = [];
		self.complications_per_hour_ = [];

		// ---- measurements ----

		var screen_size_x = _dc.getWidth();
		var screen_size_y = _dc.getHeight();

		var clock_size = _dc.getTextDimensions("00:00", Font.DOT_LARGE);
		var clock_size_x = clock_size[0];
		var clock_size_y = clock_size[1];

		var line_1_height = Render.textHeight(_dc);
		var line_2_height = Render.labelHeight(_dc) + Render.SPACING + Render.textHeight(_dc);
		var line_3_height = Render.labelHeight(_dc) + Render.SPACING + Render.textSmallHeight(_dc);

		var side_size_x = Render.iconsWidth(_dc, " ");

		var spacing_x = (
			(screen_size_x - clock_size_x) / 2
			- side_size_x
		) / 2;
		var spacing_y = (
			(screen_size_y - clock_size_y) / 2
			- line_1_height
			- line_2_height
			- line_3_height
		) / 4;


		// ---- line main ----

		self.status_.center_x = (screen_size_x - clock_size_x - side_size_x) / 2;
		self.status_.center_y = screen_size_y / 2;

		self.clock_.center_x = screen_size_x / 2;
		self.clock_.center_y = screen_size_y / 2;
		self.clock_.radius_x = clock_size[0] / 2;
		self.clock_.radius_y = clock_size[1] / 2;

		var gauges = [
			new Complication.Gauge(new Data.BodyBattery()),
			new Complication.Gauge(new Data.Stress()),
			new Complication.Gauge(new Data.Move()),
		];

		self.onLayoutGauges_(gauges, Box.PosSize (
			(screen_size_x + clock_size_x) / 2 + 2 * spacing_x,
			(screen_size_y - clock_size_y) / 2 + 2 * Font.SPACING_REGULAR,
			side_size_x,
			clock_size_y - 2 * Font.SPACING_REGULAR
		));

		self.complications_per_min_.addAll(gauges);

		// ---- line above 1 ----

		var line_above_1 = Box.ForY(
			screen_size_y,
			(screen_size_y - clock_size[1]) / 2 - spacing_y,
			-line_1_height
		);

		var weather = new Complication.Weather();
			weather.pos_x = line_above_1.center_x;
			weather.pos_y = line_above_1.center_y;
			weather.size_x = line_above_1.size_x;
			weather.size_y = line_above_1.size_y;
		self.complications_per_min_.add(weather);

		// ---- line above 2 ----

		var line_above_2 = Box.ForY(
			screen_size_y,
			line_above_1.pos_y - spacing_y,
			- (line_2_height - spacing_y)
		);

		var conditions = [
			new Complication.Condition(new Data.Rain()),
			new Complication.Condition(new Data.UV()),
			new Complication.Condition(new Data.Wind()),
		];

		self.onLayoutConditions_(conditions, line_above_2);

		self.complications_per_min_.addAll(conditions);

		// ---- line above 3 ----

		var line_above_3 = Box.ForY(
			screen_size_y,
			line_above_2.pos_y - spacing_y,
			- line_3_height
		);

		var sun_moon = new Complication.SunMoon();
			sun_moon.pos_x = line_above_3.center_x;
			sun_moon.pos_y = line_above_3.pos_y;
			sun_moon.size_x = line_above_3.size_x;
			sun_moon.size_y = line_above_3.size_y;
		self.complications_per_hour_.add(sun_moon);

		// ---- line below 1 ----

		var line_below_1 = Box.ForY(
			screen_size_y,
			(screen_size_y + clock_size[1]) / 2 + spacing_y,
			line_1_height
		);

		var seconds_size_x = Render.textWidth(_dc, "00");

		self.seconds_.pos_x = line_below_1.end_x - seconds_size_x;
		self.seconds_.pos_y = line_below_1.pos_y;
		self.seconds_.size_x = seconds_size_x;
		self.seconds_.size_y = line_below_1.size_y;

		var am_pm_size_x =
			Render.iconsWidth(_dc, "" + Font.ICON_AM_PM_BEGIN + Font.ICON_BATTERY_END) +
			Render.textSmallWidth(_dc, "am");

		if (!Data.Units.SETTINGS.is_24_hour) {
			var am_pm = new Complication.AmPm();

			am_pm.pos_x = self.seconds_.pos_x - am_pm_size_x - Render.SPACING;
			am_pm.pos_y = line_below_1.pos_y;
			am_pm.size_x = am_pm_size_x;
			am_pm.size_y = line_below_1.size_y;

			self.complications_per_hour_.add(am_pm);
		}

		var date = new Complication.Date();
			date.pos_x = line_below_1.pos_x;
			date.pos_y = line_below_1.pos_y;
			date.size_x = line_below_1.size_x - seconds_size_x - am_pm_size_x - Render.SPACING;
			date.size_y = line_below_1.size_y;
		self.complications_per_hour_.add(date);

		// ---- line below 2 ----

		var line_below_2 = Box.ForY(
			screen_size_y,
			line_below_1.end_y + spacing_y,
			line_2_height
		);

		// ---- metrics base
		self.metrics_base_= [
			new Complication.Metric(_dc, new Data.HeartRate(), 3),
			new Complication.Metric(_dc, new Data.Steps(), 3),
			new Complication.Metric(_dc, new Data.FloorsClimbed(), 3),
		];
		self.onLayoutMetrics_(self.metrics_base_, line_below_2);

		// ---- metrics alt
		self.metrics_alt_ = [
			new Complication.Metric(_dc, new Data.Calories(), 3),
			new Complication.Metric(_dc, new Data.Distance(), 3),
			new Complication.Metric(_dc, new Data.SolarIntensity(), 3),
		];
		self.onLayoutMetrics_(self.metrics_alt_, line_below_2);

		// ---- line below 3 ----

		var line_below_3 = Box.ForY(
			screen_size_y,
			line_below_2.end_y + spacing_y,
			line_3_height
		);

		self.battery_.pos_x = screen_size_x / 2 - side_size_x;
		self.battery_.pos_y = line_below_3.pos_y;
		self.battery_.size_x = 2 * side_size_x;
		self.battery_.size_y = line_below_3.size_y;
	}

	function onUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }

		// ==== update ====

		var clock = System.getClockTime();

		{
			self.status_.refresh(_dc);
			self.seconds_.refresh(_dc);

			self.refresh_(_dc, self.getMetrics_());
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

			self.render_(_dc, self.getMetrics_());
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

	static hidden function onLayoutMetrics_(_metrics as Metrics, _box as Box) as Void {
		var metrics_size = _metrics.size();

		var occupied_size_x = 0;
		for (var i = 0; i < metrics_size; ++i) {
			occupied_size_x += _metrics[i].size_x;
		}

		var spacing = (_box.size_x - occupied_size_x) / (2 * metrics_size);

		var pos_x = _box.pos_x + spacing;
		var pos_y = _box.pos_y;
		for (var i = 0; i < metrics_size; ++i) {
			var metric = _metrics[i];

			metric.pos_x = pos_x;
			metric.pos_y = pos_y;

			pos_x += 2 * spacing + metric.size_x;
		}
	}

	static hidden function onLayoutGauges_(_gauges as Gauges, _box as Box) as Void {
		var gauges_size = _gauges.size();

		var pos_x = _box.pos_x;
		var pos_y = _box.pos_y;
		var size_x = _box.size_x / gauges_size;
		var size_y = _box.size_y;

		for (var i = 0; i < gauges_size; ++i) {
			var gauge = _gauges[i];

			gauge.pos_x = pos_x;
			gauge.pos_y = pos_y;
			gauge.size_y = size_y;

			pos_x += size_x;
		}
	}

	static hidden function onLayoutConditions_(_conditions as Conditions, _box as Box) as Void {
		var conditions_size = _conditions.size();

		var pos_x = _box.pos_x;
		var pos_y = _box.pos_y;
		var size_x = _box.size_x / conditions_size;
		var size_y = _box.size_y;

		for (var i = 0; i < conditions_size; ++i) {
			var condition = _conditions[i];

			condition.pos_x = pos_x;
			condition.pos_y = pos_y;
			condition.size_x = size_x;
			condition.size_y = size_y;

			pos_x += size_x;
		}
	}
}

} // module Phase0
