// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Main {

class Clock {
	hidden var font_ as WatchUi.FontResource = Fonts.DIGITS;
	hidden var font_bold_ as WatchUi.FontResource = Fonts.DIGITS_BOLD;
	hidden var font_thin_ as WatchUi.FontResource = Fonts.DIGITS_THIN;

	var center_x as Lang.Number = 0;
	var center_y as Lang.Number = 0;

	var radius_x as Lang.Number = 0;
	var radius_y as Lang.Number = 0;

	hidden var label_ as Lang.String = "";

	function initialize(_small as Lang.Boolean) {
		if (_small) {
			self.font_ = Fonts.DIGITS_SMALL;
			self.font_bold_ = Fonts.DIGITS_SMALL_BOLD;
			self.font_thin_ = Fonts.DIGITS_SMALL_THIN;
		} else {
			self.font_ = Fonts.DIGITS;
			self.font_bold_ = Fonts.DIGITS_BOLD;
			self.font_thin_ = Fonts.DIGITS_THIN;
		}
	}

	function contains(_x as Lang.Number, _y as Lang.Number) as Lang.Boolean {
		var pos_x = self.center_x - self.radius_x;
		var pos_y = self.center_y - self.radius_y;
		var end_x = self.center_x + self.radius_x;
		var end_y = self.center_y + self.radius_y;

		return
			pos_x <= _x and _x <= end_x and
			pos_y <= _y and _y <= end_y;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var clock = System.getClockTime();

		var hour = Data.Units.convertHour(clock.hour);
		self.label_ = Lang.format("$1$:$2$", [
			hour.format("%02d"),
			clock.min.format("%02d"),
		]);
	}

	function render(_dc as Graphics.Dc, _is_night_mode as Lang.Boolean) as Void {
		if (self.label_.length() == 0) {
			self.refresh(_dc);
		}

		if (self.label_.length() == 0) {
			return;
		}

		var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

		if (_is_night_mode) {
			_dc.setColor(Render.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				self.center_x, self.center_y, self.font_, self.label_,
				justify
			);
		} else {
			_dc.setColor(Render.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				self.center_x, self.center_y, self.font_bold_,
				self.label_, justify
			);

			_dc.setColor(Render.COLOR_DARK_GRAY, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				self.center_x, self.center_y, self.font_thin_, "88:88",
				justify
			);
		}
	}
}

} // module Main
