// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

module Complication {

class Seconds extends Text {
	function initialize() {
		Text.initialize(Complications.COMPLICATION_TYPE_INVALID);
	}

	hidden function getValue_() as Lang.String {
		var clock = System.getClockTime();

		return clock.sec.format("%02d");
	}

	function renderPlaceholder(_dc as Graphics.Dc) as Void {
		Render.number(_dc, self.pos_x, self.pos_y, null, 2);
	}
}

} // module Complication
