// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Widgets {

class Clock {
	hidden var font_ as WatchUi.FontResource;
	hidden var font_bold_ as WatchUi.FontResource;
	hidden var font_thin_ as WatchUi.FontResource;

	hidden var color_ as Lang.Number;
	hidden var background_ as Lang.Number;

	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

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

		self.color_ = Application.Properties.getValue("ClockColor") as Lang.Number;
		self.background_ = Application.Properties.getValue("ClockBackground") as Lang.Number;
	}

	function contains(_x as Lang.Number, _y as Lang.Number) as Lang.Boolean {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;
		var end_x = pos_x + self.size_x;
		var end_y = pos_y + self.size_y;

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

		if (_is_night_mode) {
			_dc.setColor(self.color_, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				self.pos_x, self.pos_y, self.font_, self.label_,
				Render.JUSTIFY_LEFT
			);
		} else {
			_dc.setColor(self.background_, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				self.pos_x, self.pos_y, self.font_thin_, "88:88",
				Render.JUSTIFY_LEFT
			);

			_dc.setColor(self.color_, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(
				self.pos_x, self.pos_y, self.font_,
				self.label_, Render.JUSTIFY_LEFT
			);
		}
	}
}

} // module Widgets
