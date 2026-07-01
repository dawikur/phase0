// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {

class Seconds {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	hidden var small_ as Lang.Boolean = false;

	hidden var value_ as Lang.String = "";

	function initialize(_small as Lang.Boolean) {
		self.small_ = _small;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var clock = System.getClockTime();

		self.value_ = clock.sec.format("%02d");
	}

	function render(_dc as Graphics.Dc, _is_high_power as Lang.Boolean) as Void {
		if (_is_high_power) {
			Render.text(
				_dc,
				self.pos_x,
				self.pos_y,
				self.small_,
				self.value_,
				Render.JUSTIFY_LEFT
			);
		} else {
			Render.number(
				_dc,
				self.pos_x,
				self.pos_y,
				null,
				2,
				self.small_
			);
		}
	}
}

} // module Widgets
