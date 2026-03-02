// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Main {

class Clock {
	var center_x as Lang.Number = 0;
	var center_y as Lang.Number = 0;

	var radius_x as Lang.Number = 0;
	var radius_y as Lang.Number = 0;

	hidden var ampm_ as Lang.String = "";
	hidden var label_ as Lang.String = "";

	function initialize() {
	}

	function contains(_x as Lang.Number, _y as Lang.Number) as Lang.Boolean {
		var pos_x = self.center_x - self.radius_x;
		var pos_y = self.center_y - self.radius_y;
		var end_x = self.center_x + self.radius_x;
		var end_y = self.center_y + self.radius_y;

		return
			pos_x <= _x && _x <= end_x &&
			pos_y <= _y && _y <= end_y;
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
			_dc.setColor(Render.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(self.center_x, self.center_y, Font.DOT_LARGE, self.label_, justify);
		} else {
			_dc.setColor(Render.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(self.center_x, self.center_y, Font.DOT_LARGE_BOLD, self.label_, justify);

			_dc.setColor(Render.COLOR_BG, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(self.center_x, self.center_y, Font.DOT_LARGE_THIN, "88:88", justify);
		}

		// TODO: self.ampm_
	}
}

} // module Main
