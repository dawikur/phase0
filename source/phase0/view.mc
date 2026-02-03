// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.System;
import Toybox.ActivityMonitor;
import Toybox.UserProfile;

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

	hidden var is_night_mode_ as Lang.Boolean or Null = null;

	// ---- refresh ----
	hidden var last_refresh_min_ as Lang.Number = -1;
	hidden var last_refresh_hour_ as Lang.Number = -1;

	// ---- line above 2 ----

	// ---- line above 1 ----
	hidden const weather_ = new Label.Weather();

	// ---- line main ----
	hidden const clock_ = new Label.Clock();

	// ---- line below 1 ----
	hidden const date_ = new Label.Date();
	hidden const seconds_ = new Label.Seconds();

	// ---- line below 2 ----

	hidden var values_ as Lang.Array<Value.Base> = [];

	// ---- methods ----

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
		self.is_high_power_ = false;

		WatchUi.requestUpdate();
	}

	function onExitSleep() as Void {
		self.is_high_power_ = true;

		WatchUi.requestUpdate();
	}

	function onSettingsChanged() as Void {
		WatchUi.requestUpdate();
	}

	function onLayout(_dc as Graphics.Dc) as Void {
		self.screen_size_x_ = _dc.getWidth();
		self.screen_size_y_ = _dc.getHeight();

		// ---- measurements ----

		var clock_size = _dc.getTextDimensions("00:00", Font.DOT_LARGE);

		var regular_size = _dc.getTextDimensions("0", Font.DOT_REGULAR);
		var regular_spacing = Font.SPACING_REGULAR;

		var small_size = _dc.getTextDimensions("0", Font.DOT_SMALL);
		var small_spacing = Font.SPACING_SMALL;

		var tiny_size = _dc.getTextDimensions("0", Font.DOT_TINY);
		var tiny_spacing = Font.SPACING_TINY;

		// ---- line above 1 ----

		var line_above_1 = self.boxFor_(
			(self.screen_size_y_ - clock_size[1]) / 2 - small_spacing,
			-regular_size[1]
		);

		self.weather_.pos_x = line_above_1.center_x;
		self.weather_.pos_y = line_above_1.center_y;
		self.weather_.size_x = line_above_1.size_x;

		// ---- line main ----

		self.clock_.pos_x = self.screen_size_x_ / 2;
		self.clock_.pos_y = self.screen_size_y_ / 2;

		// ---- line below 1 ----

		var line_below_1 = self.boxFor_(
			(self.screen_size_y_ + clock_size[1]) / 2 + 2 * regular_spacing,
			regular_size[1]
		);

		self.date_.pos_x = line_below_1.pos_x;
		self.date_.pos_y = line_below_1.pos_y;

		self.seconds_.pos_x = line_below_1.end_x;
		self.seconds_.pos_y = line_below_1.pos_y;
		self.seconds_.size_x = 2 * regular_size[0];
		self.seconds_.size_y = regular_size[1];

		// ---- line below 2 ----

		self.values_ = [];

		var line_below_2 = self.boxFor_(
			line_below_1.end_y + small_spacing,
			tiny_size[1] + regular_size[1]
		);

		var pos_x = line_below_2.pos_x;
		pos_x += self.addValue_(
			_dc,
			new Value.HR(false),
			pos_x,
			line_below_2.pos_y,
			small_spacing
		);
		pos_x += self.addValue_(
			_dc,
			new Value.Steps(false),
			pos_x,
			line_below_2.pos_y,
			small_spacing
		);
		pos_x += self.addValue_(
			_dc,
			new Value.Floors(false),
			pos_x,
			line_below_2.pos_y,
			small_spacing
		);

		// ---- line below 3 ----

		var battery = new Value.Battery(true);
		var battery_width = battery.width(_dc);
		var battery_height = battery.height(_dc);

		var battery_end_y =
			self.screen_size_y_ - (
				(self.screen_size_y_ / 2) -
				Math.floor(self.secondLeg_((self.screen_size_y_ + battery_width) / 2)).toNumber()
			);

		self.addValue_(
			_dc,
			battery,
			(self.screen_size_x_ - battery_width) / 2,
			battery_end_y - battery_height,
			small_spacing
		);
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
			self.clock_.render(_dc);
			self.date_.render(_dc);

			if (self.is_high_power_) {
				self.seconds_.render(_dc);
			}
		} else {
			self.clock_.render(_dc);
			self.date_.render(_dc);

			self.weather_.render(_dc);

			if (self.is_high_power_) {
				self.seconds_.render(_dc);
			}

			for (var i = 0; i < self.values_.size(); ++i) {
				self.values_[i].render(_dc);
			}
		}
	}

	function onPartialUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }

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

		for (var i = 0; i < self.values_.size(); ++i) {
			self.values_[i].refresh(_dc);
		}
	}

	hidden function refreshMin_(_dc as Graphics.Dc) as Void {
		self.is_night_mode_ = self.isNightMode_();

		self.clock_.refresh(_dc);
		self.weather_.refresh(_dc);
	}

	hidden function refreshHour_(_dc as Graphics.Dc) as Void {
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
			return since_midnight.greaterThan(sleep_time) || since_midnight.lessThan(wake_time);
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

	hidden function addValue_(
		_dc as Graphics.Dc,
		_value as Value.Base,
		_pos_x as Lang.Number,
		_pos_y as Lang.Number,
		_spacing as Lang.Number
	) as Lang.Number {
		_value.pos_x = _pos_x;
		_value.pos_y = _pos_y;
		_value.spacing = _spacing;

		self.values_.add(_value);

		return _value.width(_dc);
	}
}

} // module Phase0
