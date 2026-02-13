// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;
import Toybox.WatchUi;

module Phase0 {

class Box {
	var size_x as Lang.Number;
	var size_y as Lang.Number;

	var pos_x as Lang.Number;
	var pos_y as Lang.Number;

	var end_x as Lang.Number;
	var end_y as Lang.Number;

	var center_x as Lang.Number;
	var center_y as Lang.Number;

	function initialize(
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_end_x as Lang.Number,
		_end_y as Lang.Number
	) {
		self.size_x = _end_x - _pos_x;
		self.size_y = _end_y - _pos_y;
		self.pos_x = _pos_x;
		self.pos_y = _pos_y;
		self.end_x = _end_x;
		self.end_y = _end_y;
		self.center_x = _pos_x + (self.size_x / 2);
		self.center_y = _pos_y + (self.size_y / 2);
	}
}

class View extends WatchUi.WatchFace {

	// ---- base ----
	hidden var screen_size_x_ as Lang.Number = 0;
	hidden var screen_size_y_ as Lang.Number = 0;

	hidden var is_visible_ as Lang.Boolean = false;
	hidden var is_high_power_ as Lang.Boolean = true;

	hidden var is_night_mode_ as Lang.Boolean = false;

	hidden var is_base_ as Lang.Boolean = true;

	// ---- refresh ----
	hidden var last_refresh_min_ as Lang.Number = -1;
	hidden var last_refresh_hour_ as Lang.Number = -1;

	// ---- line above 3 ----
	hidden const sun_moon_ = new Complication.SunMoon();

	// ---- line above 2 ----

	// ---- line above 1 ----
	hidden const weather_ = new Complication.Weather();

	// ---- line main ----
	hidden const icons_ = new Element.Icons();
	hidden const clock_ = new Element.Clock();
	hidden const bars_ = new Element.Bars();

	// ---- line below 1 ----
	hidden const date_ = new Complication.Date();
	hidden const seconds_ = new Complication.Seconds();

	// ---- line below 2 ----
	hidden var metrics_ as Complication.Metrics = [];
	hidden var metrics_alt_ as Complication.Metrics = [];

	// ---- line below 3 ----
	hidden var battery_ as Complication.Base = new Complication.Battery();

	// ---- methods ----

	function initialize() {
		WatchFace.initialize();
	}

	function onShow() as Void {
		self.is_visible_ = true;
		self.is_base_ = true;
	}

	function onHide() as Void {
		self.is_visible_ = false;
		self.is_base_ = true;
	}

	function onEnterSleep() as Void {
		self.is_base_ = true;
		WatchUi.requestUpdate();
	}

	function onExitSleep() as Void {
		self.is_base_ = true;
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
			self.is_base_ = ! self.is_base_;
			WatchUi.requestUpdate();

			return true;
		}

		var complications = [
			self.sun_moon_,
			self.weather_,
			self.date_,
			self.battery_
		];
		complications.addAll(self.getMetrics_());
		var complications_size = complications.size();
		for (var i = 0; i < complications_size; ++i) {
			var complication = complications[i];
			if (complication.contains(pos_x, pos_y)) {
				return complication.open();
			}
		}

		return false;
	}

	function onLayout(_dc as Graphics.Dc) as Void {
		self.screen_size_x_ = _dc.getWidth();
		self.screen_size_y_ = _dc.getHeight();

		// ---- measurements ----

		var clock_size = _dc.getTextDimensions("00:00", Font.DOT_LARGE);

		var regular_size = _dc.getTextDimensions("0", Font.DOT_REGULAR);
		var regular_spacing = Font.SPACING_REGULAR;

		//var small_size = _dc.getTextDimensions("0", Font.DOT_SMALL);
		var small_spacing = Font.SPACING_SMALL;

		var tiny_size = _dc.getTextDimensions("0", Font.DOT_TINY);
		//var tiny_spacing = Font.SPACING_TINY;

		// ---- line above 1 ----

		var line_above_1 = self.boxFor_(
			(self.screen_size_y_ - clock_size[1]) / 2 - small_spacing,
			-regular_size[1]
		);

		self.weather_.pos_x = line_above_1.center_x;
		self.weather_.pos_y = line_above_1.center_y;
		self.weather_.size_x = line_above_1.size_x;
		self.weather_.size_y = line_above_1.size_y;

		// ---- line above 2 ----

		var line_above_2 = self.boxFor_(
			line_above_1.pos_y - small_spacing,
			-tiny_size[1] - regular_size[1]
		);

		// ---- line above 3 ----

		var sun_moon_width = _dc.getTextWidthInPixels("00:00 00:00", Font.DOT_TINY);
		var sun_moon_pos_y = (self.screen_size_y_ / 2) -
			Math.ceil(self.secondLeg_((self.screen_size_x_ + sun_moon_width) / 2)).toNumber();

		self.sun_moon_.pos_x = self.screen_size_x_ / 2;
		self.sun_moon_.pos_y = sun_moon_pos_y;
		self.sun_moon_.size_x = line_above_2.size_x;
		self.sun_moon_.size_y = self.sun_moon_.height(_dc);
		self.sun_moon_.small = true;

		// ---- line main ----

		self.icons_.pos_x = (self.screen_size_x_ - clock_size[0] - Render.iconsWidth(_dc, "0")) / 2 + small_spacing;
		self.icons_.pos_y = self.screen_size_y_ / 2;

		self.clock_.center_x = self.screen_size_x_ / 2;
		self.clock_.center_y = self.screen_size_y_ / 2;
		self.clock_.radius_x = clock_size[0] / 2;
		self.clock_.radius_y = clock_size[1] / 2;

		self.bars_.pos_x = (self.screen_size_x_ + clock_size[0]) / 2 + regular_spacing;
		self.bars_.pos_y = (self.screen_size_y_ - clock_size[1]) / 2 + 2 * regular_spacing;
		self.bars_.size_x = (self.screen_size_x_ - clock_size[0]) / 2 - regular_spacing;
		self.bars_.size_y = clock_size[1] - 2 * regular_spacing;

		// ---- line below 1 ----

		var line_below_1 = self.boxFor_(
			(self.screen_size_y_ + clock_size[1]) / 2 + 2 * regular_spacing,
			regular_size[1]
		);

		self.date_.pos_x = line_below_1.pos_x;
		self.date_.pos_y = line_below_1.pos_y;
		self.date_.size_x = line_below_1.size_x;
		self.date_.size_y = line_below_1.size_y;

		self.seconds_.pos_x = line_below_1.end_x - 2 * regular_size[0];
		self.seconds_.pos_y = line_below_1.pos_y;
		self.seconds_.size_x = 2 * regular_size[0];
		self.seconds_.size_y = regular_size[1];

		// ---- line below 2 ----

		var line_below_2 = self.boxFor_(
			line_below_1.end_y + small_spacing,
			tiny_size[1] + regular_size[1]
		);
		var pos_x = line_below_2.pos_x;

		self.metrics_ = [];
		pos_x += self.addMetric_(
			_dc,
			self.metrics_,
			new Complication.HR(),
			pos_x,
			line_below_2.pos_y
		);
		pos_x += self.addMetric_(
			_dc,
			self.metrics_,
			new Complication.Steps(),
			pos_x,
			line_below_2.pos_y
		);
		pos_x += self.addMetric_(
			_dc,
			self.metrics_,
			new Complication.Floors(),
			pos_x,
			line_below_2.pos_y
		);

		pos_x = line_below_2.pos_x;

		self.metrics_alt_ = [];

		// ---- line below 3 ----

		var line_below_3 = self.boxFor_(
			line_below_2.end_y + regular_spacing,
			regular_size[1]
		);

		self.battery_.pos_x = line_below_3.pos_x;
		self.battery_.pos_y = line_below_3.pos_y;
		self.battery_.size_x = line_below_3.size_x;
		self.battery_.size_y = line_below_3.size_y;
	}

	function onUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }

		_dc.clearClip();

		_dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		_dc.clear();

		// ---- update ----

		var clock = System.getClockTime();

		self.refreshSec_(_dc);

		if (self.last_refresh_min_ != clock.min) {
			self.last_refresh_min_ = clock.min;
			self.refreshMin_(_dc);
		}
		if (self.last_refresh_hour_ != clock.hour) {
			self.last_refresh_hour_ = clock.hour;
			self.refreshHour_(_dc);
		}

		if (self.is_night_mode_) {
			self.clock_.render(_dc, true);
			self.icons_.render(_dc, true);
		} else {
			// -- clock --
			self.clock_.render(_dc, false);
			self.icons_.render(_dc, false);

			if (self.is_high_power_) {
				self.seconds_.render(_dc);
			} else {
				self.seconds_.renderPlaceholder(_dc);
			}

			// -- line above 3 --
			self.sun_moon_.render(_dc);

			// -- line above 2--

			// -- line above 1 --
			self.weather_.render(_dc);

			// -- line main --
			self.bars_.render(_dc);

			// -- line below 1 --
			self.date_.render(_dc);

			// -- line below 2 --
			var metrics = self.getMetrics_();
			var metrics_size = metrics.size();
			for (var i = 0; i < metrics_size; ++i) {
				metrics[i].render(_dc);
			}

			// -- line below 3 --
			self.battery_.render(_dc);
		}

	}

	function onPartialUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }
		if (self.is_night_mode_) { return; }
		if (!self.is_high_power_) { return; }

		_dc.setClip(
			self.seconds_.pos_x, self.seconds_.pos_y,
			self.seconds_.size_x, self.seconds_.size_y
		);

		_dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		_dc.clear();

		self.seconds_.refresh(_dc);
		self.seconds_.render(_dc);
	}

	hidden function refreshSec_(_dc as Graphics.Dc) as Void {
		self.seconds_.refresh(_dc);
		self.icons_.refresh(_dc);
		self.bars_.refresh(_dc);

		var metrics_size = self.metrics_.size();
		for (var i = 0; i < metrics_size; ++i) {
			self.metrics_[i].refresh(_dc);
		}
		var metrics_alt_size = self.metrics_alt_.size();
		for (var i = 0; i < metrics_alt_size; ++i) {
			self.metrics_alt_[i].refresh(_dc);
		}
	}

	hidden function refreshMin_(_dc as Graphics.Dc) as Void {
		self.is_night_mode_ = self.isNightMode_();

		self.clock_.refresh(_dc);
		self.weather_.refresh(_dc);
		self.battery_.refresh(_dc);
	}

	hidden function refreshHour_(_dc as Graphics.Dc) as Void {
		self.sun_moon_.refresh(_dc);
		self.date_.refresh(_dc);
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
			return since_midnight.greaterThan(sleep_time) or since_midnight.lessThan(wake_time);
		}
		return since_midnight.greaterThan(sleep_time) and since_midnight.lessThan(wake_time);
	}

	hidden function secondLeg_(_leg as Lang.Number) as Lang.Numeric {
		var hypotenuse = self.screen_size_x_ / 2;
		var leg = hypotenuse - _leg; // center of triangle is in the center of screen

		return Math.sqrt((hypotenuse * hypotenuse) - (leg * leg)).toNumber();
	}

	hidden function boxFor_(_y as Lang.Number, _dy as Lang.Number) as Box {
		var pos_y = 0;
		var end_y = 0;

		if (_dy < 0) { // above
			pos_y = _y + _dy;
			end_y = _y;
		} else { // below
			pos_y = _y;
			end_y = _y + _dy;
		}

		var size_pos = Math.floor(self.secondLeg_(pos_y) * 2).toNumber();
		var size_end = Math.floor(self.secondLeg_(end_y) * 2).toNumber();

		var size_x = size_pos < size_end ? size_pos : size_end;
		var pos_x = (self.screen_size_x_ - size_x) / 2;
		var end_x = pos_x + size_x;

		return new Box(
			pos_x,
			pos_y,
			end_x,
			end_y
		);
	}

	hidden function addMetric_(
		_dc as Graphics.Dc,
		_metrics as Complication.Metrics,
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

	hidden function getMetrics_() as Complication.Metrics {
		if (self.metrics_alt_.size() == 0) {
			return self.metrics_;
		}

		return
			self.is_base_ ?
			self.metrics_ :
			self.metrics_alt_;
	}
}

} // module Phase0
