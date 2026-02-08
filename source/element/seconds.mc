// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Element {

class Seconds extends Base {
	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	function initialize() {
		Base.initialize();
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var clock = System.getClockTime();

		self.label_ = clock.sec.format("%02d");
	}

	function renderPlaceholder(_dc as Graphics.Dc) as Void {
		Render.number(_dc, self.pos_x, self.pos_y, null, 2);
	}
}

} // module Element
