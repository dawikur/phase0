// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.System;

module Phase0 {

/*
 * initialize //- construction
 * onLayout   //- store screen size, recalculate layout
 * onShow     //- ready to be visible
 * onUpdate   //- full redraw; every second in High Power Mode
 *
 * onEnterSleep    //- entering Low Power Mode
 * onPartialUpdate //- partial redraw (only seconds); every second
 * onUpdate        //- full redraw (w/o seconds); every minute in low power mode
 * onExitSleep     //- exiting low power mode
 *
 * onHide     //- will be hidden

	0xFFAA00 Pure Orange
	0x0055FF Pure Blue
	0x55FF00 Pure Green
	0xFF5500 Pure Red
	0x00FFFF Pure Cyan
	0xFF00FF Pure Magenta
	0xFFFF00 Pure Yellow

	0xAA5500 Dark Orange
	0x0055AA Dark Blue
	0x55AA00 Dark Green
	0xAA0000 Dark Red
	0x00AAAA Dark Cyan
	0xAA00AA Dark Magenta
	0xAAAA00 Dark Yellow

	System.getSystemStats()
		battery as Lang.Float
		charging as Lang.Boolean
		solarIntensity as Lang.Number or Null

	System.getDeviceSettings()
		alarmCount as Lang.Number
		distanceUnits as System.UnitsSystem
		doNotDisturb as Lang.Boolean
		elevationUnits as System.UnitsSystem
		heightUnits as System.UnitsSystem
		is24Hour as Lang.Boolean
		notificationCount as Lang.Number
		phoneConnected as Lang.Boolean
		requiredBurnInProtection as Lang.Boolean
		weightUnits as System.UnitsSystem
 */

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

	// ---- general ----

	hidden const bezel_ = new Element.Bezel();

	// ---- line above 1 ----
	hidden const weather_ = new Element.Weather();

	// ---- line main ----
	hidden const clock_ = new Element.Clock();

	// ---- line below 1 ----
	hidden const date_ = new Element.Date();
	hidden const seconds_ = new Element.Seconds();

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
		var regular_padding = Font.STYLE_REGULAR.size;

		//var small_width = Font.STYLE_SMALL.size * (typeface_zero.width + 1);
		var small_height = Font.STYLE_SMALL.size * Font.TYPEFACE.height;
		var small_padding = Font.STYLE_SMALL.size;

		// ---- general ----

		self.bezel_.size_x = self.screen_size_x_;
		self.bezel_.size_y = self.screen_size_y_;

		// ---- line main ----

		var clock_size_y = Font.STYLE_REGULAR.size * Font.DIGITS.height;
		var clock_pos_y = (self.screen_size_y_ - clock_size_y) / 2;
		var clock_end_y = clock_pos_y + clock_size_y;

		var clock_size_x = Font.STYLE_REGULAR.size * (4 * digit_zero.width + digit_colon.width + 4);
		var clock_pos_x = (self.screen_size_x_ - clock_size_x) / 2;
		//var clock_end_x = clock_pos_x + clock_size_x;

		self.clock_.pos_x = clock_pos_x;
		self.clock_.pos_y = clock_pos_y;
		self.clock_.size_x = clock_size_x;
		self.clock_.size_y = clock_size_y;

		// ---- line below 1 ----

		var line_bottom_1_size_y = regular_height;
		var line_bottom_1_pos_y = clock_end_y + 2 * regular_padding;
		var line_bottom_1_end_y = line_bottom_1_pos_y + line_bottom_1_size_y;

		var line_bottom_1_size_x = Math.floor(self.secondLeg_(line_bottom_1_end_y) * 2).toNumber() - 2 * regular_padding;
		var line_bottom_1_pos_x = (self.screen_size_x_ - line_bottom_1_size_x) / 2;
		var line_bottom_1_end_x = line_bottom_1_pos_x + line_bottom_1_size_x;

		self.date_.pos_x = line_bottom_1_pos_x;
		self.date_.pos_y = line_bottom_1_pos_y;
		self.date_.size_x = line_bottom_1_size_x;
		self.date_.size_y = line_bottom_1_size_y;

		self.seconds_.pos_x = line_bottom_1_end_x - (2 * regular_width);
		self.seconds_.pos_y = line_bottom_1_pos_y;
		self.seconds_.size_x = 2 * regular_width;
		self.seconds_.size_y = line_bottom_1_size_y;

		// ---- line above 1 ----

		var line_top_1_size_y = small_height;
		var line_top_1_pos_y = clock_pos_y - 2 * small_padding - small_height;
		//var line_top_1_end_y = line_top_1_pos_y + line_top_1_size_y;

		//var line_top_1_size_x = Math.ceil(self.secondLeg_(line_top_1_pos_y) * 2).toNumber();
		//var line_top_1_pos_x = (self.screen_size_.x - line_top_1_size_x) / 2;
		var line_top_1_size_x = line_bottom_1_size_x;
		var line_top_1_pos_x = line_bottom_1_pos_x;
		//var line_top_1_end_x = line_top_1_pos_x + line_top_1_size_x;

		self.weather_.pos_x = line_top_1_pos_x;
		self.weather_.pos_y = line_top_1_pos_y;
		self.weather_.size_x = line_top_1_size_x;
		self.weather_.size_y = line_top_1_size_y;
	}

	function onUpdate(_dc as Graphics.Dc) as Void {
		if (!self.is_visible_) { return; }

		_dc.clearClip();

		_dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		_dc.clear();

		self.bezel_.render(_dc);

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

			self.bezel_.onNightMode(is_night_mode);
			self.clock_.onNightMode(is_night_mode);
		}

		self.clock_.refresh();
		self.weather_.refresh();
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
		var half_screen_ = self.screen_size_x_ / 2;
		var hypotenuse = half_screen_ - 2;
		var leg = half_screen_ - _leg; // center of triangle is in the center of screen

		return Math.sqrt((hypotenuse * hypotenuse) - (leg * leg)).toNumber();
	}
}

} // module Phase0
