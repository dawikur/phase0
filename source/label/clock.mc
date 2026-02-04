// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Label {

class Clock {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	hidden var label_ as Lang.String = "";

	hidden var fg_style_ as Label.Style;
	hidden var bg_style_ as Label.Style;

	hidden var is_24_Hour_ as Lang.Boolean;

	hidden var ampm_ as Lang.String or Null = null;
	hidden var ampm_padding_ as Lang.Number = 0;
	hidden var ampm_style_ as Label.Style;

	function initialize() {
		var device_settings = System.getDeviceSettings();
		self.is_24_Hour_ = device_settings.is24Hour;

		self.fg_style_ = new Label.Style(Font.DOT_LARGE, 0xFFAA00);
		self.bg_style_ = new Label.Style(Font.DOT_LARGE_THIN, 0x555555);
		self.ampm_style_ = new Label.Style(Font.DOT_SMALL, 0xAA5500);
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label_.length() == 0) {
			self.refresh(_dc);
		}

		if (self.label_.length() == 0) {
			return;
		}

		var label = self.label_;

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

		self.fg_style_.draw(_dc, pos_x, pos_y, label, justify);
		self.bg_style_.draw(_dc, pos_x, pos_y, "00:00", justify);

		if (self.ampm_ != null) {
			var ampm_ = self.ampm_ as Lang.String;

			pos_x += self.ampm_padding_;

			self.ampm_style_.draw(_dc, pos_x, pos_y, ampm_, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var clock = System.getClockTime();

		if (self.is_24_Hour_) {
			self.ampm_ = null;

			self.ampm_padding_ = 0;

			self.label_ = Lang.format("$1$:$2$", [
				clock.hour.format("%02d"),
				clock.min.format("%02d"),
			]);
		} else {
			var hour = clock.hour % 12;
			if (hour == 0) {
				hour = 12;
			}

			self.ampm_ = clock.hour < 12 ? "a\nm" : "p\nm";

			self.ampm_padding_ += _dc.getTextWidthInPixels("xx", Font.DOT_SMALL);
			self.ampm_padding_ += _dc.getTextWidthInPixels("88:88", Font.DOT_LARGE_THIN) / 2;

			self.label_ = Lang.format("$1$:$2$", [
				hour.format("%02d"),
				clock.min.format("%02d"),
			]);

		}
	}
}

} // module Label
