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
	hidden const weather_ = new Element.Weather();

	// ---- line main ----
	hidden const clock_ = new Element.Clock();

	// ---- line below 1 ----
	hidden const date_ = new Element.Date();
	hidden const seconds_ = new Element.Seconds();

	// ---- line below 2 ----

	hidden const hr_ = new Element.HR();
	hidden const steps_ = new Element.Steps();

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

		var clock_size = _dc.getTextDimensions("00:00", Font.DIGITS_REGULAR);

		var regular_size = _dc.getTextDimensions("0", Font.DOT_REGULAR);
		var regular_spacing = 3;

		var small_size = _dc.getTextDimensions("0", Font.DOT_SMALL);
		var small_spacing = 2;

		var tiny_size = _dc.getTextDimensions("0", Font.DOT_TINY);
		//var tiny_spacing = 1;

		// ---- line above 1 ----

		var line_above_1 = self.boxFor_(
			(self.screen_size_y_ - clock_size[1]) / 2 - small_spacing,
			-regular_size[1]
		);

		self.weather_.pos_x = line_above_1.center_x;
		self.weather_.pos_y = line_above_1.center_y;
		self.weather_.size_x = line_above_1.size_x;
		self.weather_.justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

		// ---- line main ----

		self.clock_.pos_x = self.screen_size_x_ / 2;
		self.clock_.pos_y = self.screen_size_y_ / 2;
		self.clock_.justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

		// ---- line below 1 ----

		var line_below_1 = self.boxFor_(
			(self.screen_size_y_ + clock_size[1]) / 2 + 2 * regular_spacing,
			regular_size[1]
		);

		self.date_.pos_x = line_below_1.pos_x;
		self.date_.pos_y = line_below_1.pos_y;
		self.date_.justify = Graphics.TEXT_JUSTIFY_LEFT;

		self.seconds_.pos_x = line_below_1.end_x;
		self.seconds_.pos_y = line_below_1.pos_y;
		self.seconds_.justify = Graphics.TEXT_JUSTIFY_RIGHT;
		self.seconds_.size_x = 2 * regular_size[0];
		self.seconds_.size_y = regular_size[1];

		// ---- line below 2 ----

		var line_below_2 = self.boxFor_(
			line_below_1.end_y + regular_spacing,
			tiny_size[1] + small_spacing + small_size[1]
		);

		self.hr_.pos_x = line_below_2.pos_x;
		self.hr_.pos_y = line_below_2.pos_y;
		self.hr_.label_height = tiny_size[1] + small_spacing;
		self.hr_.field_count = 3;
		self.hr_.field_width = small_size[0];
		self.hr_.field_height = small_size[1] - small_spacing;
		self.hr_.gauge_width = small_spacing;

		self.steps_.pos_x = line_below_2.pos_x + 3 * (small_size[0] + small_spacing);
		self.steps_.pos_y = line_below_2.pos_y;
		self.steps_.label_height = tiny_size[1] + small_spacing;
		self.steps_.field_count = 3;
		self.steps_.field_width = small_size[0];
		self.steps_.field_height = small_size[1] - small_spacing;
		self.steps_.gauge_width = small_spacing;
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

		self.clock_.render(_dc);
		self.date_.render(_dc);
		self.weather_.render(_dc);

		if (self.is_high_power_) {
			self.seconds_.render(_dc);
		}

		self.hr_.render(_dc);
		self.steps_.render(_dc);
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
	}

	hidden function refreshMin_(_dc as Graphics.Dc) as Void {
		var is_night_mode = self.isNightMode_();
		if (self.is_night_mode_ != is_night_mode) {
			self.is_night_mode_ = is_night_mode;

			self.clock_.onNightMode(is_night_mode);
		}

		self.clock_.refresh(_dc);
		self.weather_.refresh(_dc);

		self.hr_.refresh(_dc);
		self.steps_.refresh(_dc);
	}

	hidden function refreshHour_(_dc as Graphics.Dc) as Void {
		self.date_.refresh(_dc);
	}

	hidden function isNightMode_() as Lang.Boolean {
		var userProfile = UserProfile.getProfile();
		if (userProfile.sleepTime == null) {
			return false;
		}
		if (userProfile.wakeTime == null) {
			return false;
		}

		var sleepTime = userProfile.sleepTime as Time.Duration;
		var wakeTime = userProfile.wakeTime as Time.Duration;

		var now = Time.now();
        var midnight = Time.today();
        var since_midnight = now.subtract(midnight) as Time.Duration;

		if(sleepTime.greaterThan(wakeTime)) {
			return since_midnight.greaterThan(sleepTime) || since_midnight.lessThan(wakeTime);
		}
		return since_midnight.greaterThan(sleepTime) and since_midnight.lessThan(wakeTime);
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
}

} // module Phase0
