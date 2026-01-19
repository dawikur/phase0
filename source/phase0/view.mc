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

	// ---- debugging ----

	hidden var line_above_1_size_x_ as Lang.Number = 0;
	hidden var line_above_1_size_y_ as Lang.Number = 0;
	hidden var line_above_1_pos_x_ as Lang.Number = 0;
	hidden var line_above_1_pos_y_ as Lang.Number = 0;

	hidden var line_below_1_size_x_ as Lang.Number = 0;
	hidden var line_below_1_size_y_ as Lang.Number = 0;
	hidden var line_below_1_pos_x_ as Lang.Number = 0;
	hidden var line_below_1_pos_y_ as Lang.Number = 0;

	hidden var line_below_2_size_x_ as Lang.Number = 0;
	hidden var line_below_2_size_y_ as Lang.Number = 0;
	hidden var line_below_2_pos_x_ as Lang.Number = 0;
	hidden var line_below_2_pos_y_ as Lang.Number = 0;

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

	function onLayout(dc as Graphics.Dc) as Void {
		self.screen_size_x_ = dc.getWidth();
		self.screen_size_y_ = dc.getHeight();

		// ---- glyphs ----

		var digit_colon = Font.DIGITS.getOrEmpty(':');
		var digit_zero = Font.DIGITS.getOrEmpty('0');
		var typeface_zero = Font.TYPEFACE.getOrEmpty('0');

		Test.assertNotEqualMessage(digit_colon.width, 0, "Can't find glyph for DIGIT ':'");
		Test.assertNotEqualMessage(digit_zero.width, 0, "Can't find glyph for DIGIT '0'");
		Test.assertNotEqualMessage(typeface_zero.width, 0, "Can't find glyph for TYPEFACE '0'");

		// ---- measurements ----

		var regular_width = Font.STYLE_REGULAR.size * (typeface_zero.width + 1);
		var regular_height = Font.STYLE_REGULAR.size * Font.TYPEFACE.height;
		var regular_spacing = Font.STYLE_REGULAR.size;

		var small_width = Font.STYLE_SMALL.size * (typeface_zero.width + 1);
		var small_height = Font.STYLE_SMALL.size * Font.TYPEFACE.height;
		var small_spacing = Font.STYLE_SMALL.size;

		//var micro_width = Font.STYLE_MICRO.size * (typeface_zero.width + 1);
		var micro_height = Font.STYLE_MICRO.size * Font.TYPEFACE.height;
		//var micro_spacing = Font.STYLE_MICRO.size;

		// ---- line main ----

		var clock_size_y = Font.STYLE_REGULAR.size * Font.DIGITS.height;
		var clock_pos_y = (self.screen_size_y_ - clock_size_y) / 2;
		var clock_end_y = clock_pos_y + clock_size_y;

		var clock_size_x = Font.STYLE_REGULAR.size * (4 * digit_zero.width + digit_colon.width + 4);
		var clock_pos_x = (self.screen_size_x_ - clock_size_x) / 2;
		//var clock_end_x = clock_pos_x + clock_size_x;

		self.clock_.pos_x = clock_pos_x;
		self.clock_.pos_y = clock_pos_y;

		// ---- line below 1 ----

		var line_below_1_size_y = regular_height;
		var line_below_1_pos_y = clock_end_y + 2 * regular_spacing;
		var line_below_1_end_y = line_below_1_pos_y + line_below_1_size_y;

		var line_below_1_size_x = Math.floor(self.secondLeg_(line_below_1_end_y) * 2).toNumber() - 2 * regular_spacing;
		var line_below_1_pos_x = (self.screen_size_x_ - line_below_1_size_x) / 2;
		var line_below_1_end_x = line_below_1_pos_x + line_below_1_size_x;

		self.date_.pos_x = line_below_1_pos_x;
		self.date_.pos_y = line_below_1_pos_y;

		self.seconds_.pos_x = line_below_1_end_x - (2 * regular_width) + regular_spacing;
		self.seconds_.pos_y = line_below_1_pos_y;
		self.seconds_.size_x = 2 * regular_width;
		self.seconds_.size_y = regular_height;

		// ---- line below 2 ----

		var line_below_2_size_y = micro_height + small_spacing + small_height;
		var line_below_2_pos_y = line_below_1_end_y + regular_spacing;
		var line_below_2_end_y = line_below_2_pos_y + line_below_2_size_y;

		var line_below_2_size_x = Math.floor(self.secondLeg_(line_below_2_end_y) * 2).toNumber() - regular_spacing;
		var line_below_2_pos_x = (self.screen_size_x_ - line_below_2_size_x) / 2;
		//var line_below_2_end_x = line_below_2_pos_x + line_below_2_size_x;

		self.hr_.pos_x = line_below_2_pos_x;
		self.hr_.pos_y = line_below_2_pos_y;
		self.hr_.label_height = micro_height + small_spacing;
		self.hr_.field_count = 3;
		self.hr_.field_width = small_width;
		self.hr_.field_height = small_height - small_spacing - Font.STYLE_SMALL.weight;
		self.hr_.gauge_width = Font.STYLE_SMALL.weight;

		self.steps_.pos_x = line_below_2_pos_x + 3 * (small_width + small_spacing);
		self.steps_.pos_y = line_below_2_pos_y;
		self.steps_.label_height = micro_height + small_spacing;
		self.steps_.field_count = 3;
		self.steps_.field_width = small_width;
		self.steps_.field_height = small_height - small_spacing - Font.STYLE_SMALL.weight;
		self.steps_.gauge_width = Font.STYLE_SMALL.weight;

		// ---- line above 1 ----

		var line_above_1_size_y = small_height;
		var line_above_1_end_y = clock_pos_y -  2 * regular_spacing;
		var line_above_1_pos_y = line_above_1_end_y - line_above_1_size_y;

		//var line_above_1_size_x = Math.ceil(self.secondLeg_(line_above_1_pos_y) * 2).toNumber();
		//var line_above_1_pos_x = (self.screen_size_.x - line_above_1_size_x) / 2;
		//var line_above_1_end_x = line_above_1_pos_x + line_above_1_size_x;
		var line_above_1_size_x = line_below_1_size_x;
		var line_above_1_pos_x = line_below_1_pos_x;
		//var line_above_1_end_x = line_below_1_end_x;

		self.weather_.pos_x = line_above_1_pos_x;
		self.weather_.pos_y = line_above_1_pos_y;
		self.weather_.size_x = line_above_1_size_x;

		// ---- debugging ----

		self.line_above_1_size_y_ = line_above_1_size_y;
		self.line_above_1_size_x_ = line_above_1_size_x;
		self.line_above_1_pos_y_ = line_above_1_pos_y;
		self.line_above_1_pos_x_ = line_above_1_pos_x;

		self.line_below_1_size_y_ = line_below_1_size_y;
		self.line_below_1_size_x_ = line_below_1_size_x;
		self.line_below_1_pos_y_ = line_below_1_pos_y;
		self.line_below_1_pos_x_ = line_below_1_pos_x;

		self.line_below_2_size_y_ = line_below_2_size_y;
		self.line_below_2_size_x_ = line_below_2_size_x;
		self.line_below_2_pos_y_ = line_below_2_pos_y;
		self.line_below_2_pos_x_ = line_below_2_pos_x;
	}

	function onUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }

		_dc.clearClip();

		_dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		_dc.clear();

		// ---- debugging ----

		if (false) {
			_dc.setColor(0x555555, Graphics.COLOR_BLACK);
			_dc.fillRectangle(
				self.line_above_1_pos_x_, self.line_above_1_pos_y_,
				self.line_above_1_size_x_, self.line_above_1_size_y_
			);

			_dc.fillRectangle(
				self.line_below_1_pos_x_, self.line_below_1_pos_y_,
				self.line_below_1_size_x_, self.line_below_1_size_y_
			);

			_dc.fillRectangle(
				self.line_below_2_pos_x_, self.line_below_2_pos_y_,
				self.line_below_2_size_x_, self.line_below_2_size_y_
			);
		}

		// ---- update ----

		var clock = System.getClockTime();

		self.refreshSec_();

		if (self.last_refresh_min_ != clock.min) {
			self.last_refresh_min_ = clock.min;
			self.refreshMin_();
		}
		if (self.last_refresh_hour_ != clock.hour) {
			self.last_refresh_hour_ = clock.hour;
			self.refreshHour_();
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

		self.seconds_.refresh();
		self.seconds_.render(_dc);
	}

	hidden function refreshSec_() as Void {
		self.seconds_.refresh();
	}

	hidden function refreshMin_() as Void {
		var is_night_mode = self.isNightMode_();
		if (self.is_night_mode_ != is_night_mode) {
			self.is_night_mode_ = is_night_mode;

			self.clock_.onNightMode(is_night_mode);
		}

		self.clock_.refresh();
		self.weather_.refresh();

		self.hr_.refresh();
		self.steps_.refresh();
	}

	hidden function refreshHour_() as Void {
		self.date_.refresh();
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
}

} // module Phase0
