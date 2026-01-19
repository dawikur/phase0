// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Element {

class Clock extends Label {
	hidden var is24Hour_ as Lang.Boolean;

	hidden var day_styles_ as Lang.Array<Element.Style>;
	hidden var night_styles_ as Lang.Array<Element.Style>;

	function initialize() {
		Label.initialize();

		self.day_styles_ = [
			new Element.Style(Font.DIGITS, Font.STYLE_REGULAR, 0xAA5500),
			new Element.Style(Font.DIGITS_BLURED, Font.STYLE_REGULAR_THIN, 0xAA5500),
			new Element.Style(Font.DIGITS, Font.STYLE_REGULAR_THIN, 0xFFAA00),
		];
		self.night_styles_ = [
			new Element.Style(Font.DIGITS, Font.STYLE_REGULAR, 0x555555),
			new Element.Style(Font.DIGITS_BLURED, Font.STYLE_REGULAR_THIN, 0x555555),
			new Element.Style(Font.DIGITS, Font.STYLE_REGULAR_THIN, 0xAAAAAA),
		];

		self.styles = self.day_styles_;

		var deviceSettings = System.getDeviceSettings();
		self.is24Hour_ = deviceSettings.is24Hour;
	}

	function get_() as Lang.String {
		var clock = System.getClockTime();

		if (self.is24Hour_) {
			return Utils.joinStr(":", [
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

		return Utils.joinStr(":", [
			hour.format("%02d"),
			clock.min.format("%02d"),
		]);
	}

	function onNightMode(_is_night_mode as Lang.Boolean) as Void {
		if (_is_night_mode) {
			self.styles = self.night_styles_;
		} else {
			self.styles = self.day_styles_;
		}
	}
}

} // module Element
