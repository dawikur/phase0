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
	hidden var ampm_ as Lang.String or Null = null;
	hidden var ampm_padding_ as Lang.Number = 0;

	hidden var is_24_Hour_ as Lang.Boolean;

	function initialize() {
		var device_settings = System.getDeviceSettings();
		self.is_24_Hour_ = device_settings.is24Hour;
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label_ == "") {
			self.refresh(_dc);
		}

		if (self.label_ == "") {
			return;
		}

		var label = self.label_;

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		_dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, Font.DOT_LARGE_THIN, "88:88", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

		_dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, Font.DOT_LARGE_BLURRED, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

		_dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, Font.DOT_LARGE_THIN, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

		if (self.ampm_ != null) {
			var ampm_ = self.ampm_ as Lang.String;

			pos_x += self.ampm_padding_;

			_dc.setColor(0xAA5500, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(pos_x, pos_y, Font.DOT_SMALL, ampm_, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
