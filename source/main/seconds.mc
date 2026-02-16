// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

module Main {

class Seconds {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	hidden var value_ as Lang.String = "";

	function initialize() {
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var clock = System.getClockTime();

		self.value_ = clock.sec.format("%02d");
	}

	function render(_dc as Graphics.Dc, _is_high_power as Lang.Boolean) as Void {
		if (_is_high_power) {
			Render.text(_dc, self.pos_x, self.pos_y, self.value_, Graphics.TEXT_JUSTIFY_LEFT);
		} else {
			Render.number(_dc, self.pos_x, self.pos_y, null, 2);
		}
	}
}

} // module Main
