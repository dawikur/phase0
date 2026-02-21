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

	hidden const clock_ = new Main.Clock();
	hidden const status_ = new Main.Status();
	hidden const seconds_ = new Main.Seconds();

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

		self.metrics_base_ = [];
		self.metrics_alt_ = [];

		// ---- measurements ----

		var screen_size_x = _dc.getWidth();
		var screen_size_y = _dc.getHeight();

		var clock_size = _dc.getTextDimensions("00:00", Font.DOT_LARGE);

		var regular_size = _dc.getTextDimensions("0", Font.DOT_REGULAR);
		var regular_spacing = Font.SPACING_REGULAR;

		//var small_size = _dc.getTextDimensions("0", Font.DOT_SMALL);
		var small_spacing = Font.SPACING_SMALL;

		var tiny_size = _dc.getTextDimensions("0", Font.DOT_TINY);
		//var tiny_spacing = Font.SPACING_TINY;

		// ---- line main ----

		self.status_.pos_x = small_spacing + (
			screen_size_x - clock_size[0] - Render.iconsWidth(_dc, "0")
		) / 2;
		self.status_.pos_y = screen_size_y / 2;

		self.clock_.center_x = screen_size_x / 2;
		self.clock_.center_y = screen_size_y / 2;
		self.clock_.radius_x = clock_size[0] / 2;
		self.clock_.radius_y = clock_size[1] / 2;

		var gauges = new Complication.Gauges();
		gauges.add(new Complication.Gauge(new Data.BodyBattery()));
		gauges.add(new Complication.Gauge(new Data.Stress()));
		gauges.add(new Complication.Gauge(new Data.Move()));

		self.addComplication_(
			_dc,
			self.complications_per_min_,
			gauges,
			(screen_size_x + clock_size[0]) / 2 + regular_spacing,
			(screen_size_y - clock_size[1]) / 2 + 2 * regular_spacing,
			(screen_size_x - clock_size[0]) / 2 - regular_spacing,
			clock_size[1] - 2 * regular_spacing
		);

		// ---- line above 1 ----

		var line_above_1 = Box.ForY(
			screen_size_x,
			(screen_size_y - clock_size[1]) / 2 - small_spacing,
			-regular_size[1]
		);

		self.addComplication_(
			_dc,
			self.complications_per_min_,
			new Complication.Weather(),
			line_above_1.center_x,
			line_above_1.center_y,
			line_above_1.size_x,
			line_above_1.size_y
		);

		// ---- line above 2 ----

		var line_above_2 = Box.ForY(
			screen_size_y,
			line_above_1.pos_y - small_spacing,
			-tiny_size[1] - regular_size[1]
		);

		// ---- line above 3 ----

		{
			var sun_moon = new Complication.SunMoon();

			var sun_moon_width = _dc.getTextWidthInPixels(
				"00:00 00:00", Font.DOT_TINY
			);
			var sun_moon_pos_y = (screen_size_y / 2) - Math.ceil(Box.secondLeg(
				screen_size_x, (screen_size_x + sun_moon_width) / 2
			)).toNumber();

			sun_moon.pos_x = screen_size_x / 2;
			sun_moon.pos_y = sun_moon_pos_y;
			sun_moon.size_x = line_above_2.size_x;
			sun_moon.size_y = sun_moon.height(_dc);

			self.complications_per_hour_.add(sun_moon);
		}

		// ---- line below 1 ----

		var line_below_1 = Box.ForY(
			screen_size_y,
			(screen_size_y + clock_size[1]) / 2 + 2 * regular_spacing,
			regular_size[1]
		);

		self.seconds_.pos_x = line_below_1.end_x - 2 * regular_size[0];
		self.seconds_.pos_y = line_below_1.pos_y;
		self.seconds_.size_x = 2 * regular_size[0];
		self.seconds_.size_y = regular_size[1];

		self.addComplication_(
			_dc,
			self.complications_per_hour_,
			new Complication.Date(),
			line_below_1.pos_x,
			line_below_1.pos_y,
			line_below_1.size_x - self.seconds_.size_x,
			line_below_1.size_y - self.seconds_.size_y
		);

		// ---- line below 2 ----

		var line_below_2 = Box.ForY(
			screen_size_y,
			line_below_1.end_y + small_spacing,
			tiny_size[1] + regular_size[1]
		);

		var pos_x = line_below_2.pos_x;
		pos_x += self.addMetric_(
			_dc,
			self.metrics_base_,
			new Complication.Metric(new Data.HeartRate()),
			pos_x,
			line_below_2.pos_y
		);
		pos_x += self.addMetric_(
			_dc,
			self.metrics_base_,
			new Complication.Metric(new Data.Steps()),
			pos_x,
			line_below_2.pos_y
		);
		pos_x += self.addMetric_(
			_dc,
			self.metrics_base_,
			new Complication.Metric(new Data.FloorsClimbed()),
			pos_x,
			line_below_2.pos_y
		);

		pos_x = line_below_2.pos_x;
		pos_x += self.addMetric_(
			_dc,
			self.metrics_alt_,
			new Complication.Metric(new Data.Calories()),
			pos_x,
			line_below_2.pos_y
		);
		pos_x += self.addMetric_(
			_dc,
			self.metrics_alt_,
			new Complication.Metric(new Data.Distance()),
			pos_x,
			line_below_2.pos_y
		);
		pos_x += self.addMetric_(
			_dc,
			self.metrics_alt_,
			new Complication.Metric(new Data.SolarIntensity()),
			pos_x,
			line_below_2.pos_y
		);

		// ---- line below 3 ----

		var line_below_3 = Box.ForY(
			screen_size_y,
			line_below_2.end_y + regular_spacing,
			regular_size[1]
		);

		self.addComplication_(
			_dc,
			self.complications_per_min_,
			new Complication.Battery(),
			line_below_3.pos_x,
			line_below_3.pos_y,
			line_below_3.size_x,
			line_below_3.size_y
		);
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
		} else {
			self.clock_.render(_dc, false);
			self.status_.render(_dc, false);

			self.seconds_.render(_dc, self.is_high_power_);

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

	hidden function addComplication_(
		_dc as Graphics.Dc,
		_complications as Complications,
		_complication as Complication.Base,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_size_x as Lang.Number,
		_size_y as Lang.Number
	) as Void {
		_complication.pos_x = _pos_x;
		_complication.pos_y = _pos_y;
		_complication.size_x = _size_x;
		_complication.size_y = _size_y;

		_complications.add(_complication);
	}

	hidden function addMetric_(
		_dc as Graphics.Dc,
		_metrics as Metrics,
		_metric as Complication.Metric,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number
	) as Lang.Number {
		_metric.pos_x = _pos_x;
		_metric.pos_y = _pos_y;

		_metric.size_x = _metric.width(_dc);
		_metric.size_y = _metric.height(_dc);

		_metrics.add(_metric);

		return _metric.size_x;
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
}

} // module Phase0
