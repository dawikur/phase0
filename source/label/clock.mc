// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Label {

class Clock extends Base {
	hidden var is_24_Hour_ as Lang.Boolean;

	function initialize() {
		Base.initialize();

		self.styles = [
			new Label.Style(Font.DOT_LARGE_BLURRED, 0xAA5500),
			new Label.Style(Font.DOT_LARGE_THIN, 0xFFAA00),
		];

		var device_settings = System.getDeviceSettings();
		self.is_24_Hour_ = device_settings.is24Hour;
	}

	function get_() as Lang.String {
		var clock = System.getClockTime();

		if (self.is_24_Hour_) {
			return Lang.format("$1$:$2$", [
				clock.hour.format("%02d"),
				clock.min.format("%02d"),
			]);
		}
		var hour = clock.hour % 12;
		if (hour == 0) {
			hour = 12;
		}

		// TODO: use it
		// var ampm = clock.hour < 12 ? "am" : "pm";

		return Lang.format("$1$:$2$", [
			hour.format("%02d"),
			clock.min.format("%02d"),
		]);
	}
}

} // module Label
