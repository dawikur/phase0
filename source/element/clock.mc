// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Element {

class Clock {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	hidden var label_ as Lang.String = "";

	hidden var is_24_Hour_ as Lang.Boolean;

	hidden var ampm_ as Lang.String or Null = null;
	hidden var ampm_padding_ as Lang.Number = 0;

	function initialize() {
		var device_settings = System.getDeviceSettings();
		self.is_24_Hour_ = device_settings.is24Hour;
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label_.length() == 0) {
			self.refresh(_dc);
		}

		if (self.label_.length() == 0) {
			return;
		}

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

		_dc.setColor(Render.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, Font.DOT_LARGE, self.label_, justify);

		_dc.setColor(Render.COLOR_BG, Graphics.COLOR_TRANSPARENT);
		_dc.drawText(pos_x, pos_y, Font.DOT_LARGE_THIN, "88:88", justify);

		if (self.ampm_ != null) {
			var ampm_ = self.ampm_ as Lang.String;

			pos_x += self.ampm_padding_;

			Render.label(_dc, pos_x, pos_y, ampm_, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

			self.ampm_ =
				clock.hour < 12 ?
				"A\nM" :
				"P\nM";

			self.ampm_padding_ += _dc.getTextWidthInPixels("88:88", Font.DOT_LARGE_THIN) / 2;
			self.ampm_padding_ += _dc.getTextWidthInPixels("x", Font.DOT_SMALL);

			self.label_ = Lang.format("$1$:$2$", [
				hour.format("%02d"),
				clock.min.format("%02d"),
			]);

		}
	}
}

} // module Element
