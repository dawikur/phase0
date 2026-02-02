// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Label {

class Seconds extends Base {
	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	function initialize() {
		Base.initialize();

		self.styles_ = [
			new Label.Style(Font.DOT_REGULAR, 0x555555),
		];
		self.justify_ = Graphics.TEXT_JUSTIFY_RIGHT;
	}

	function get_() as Lang.String {
		var clock = System.getClockTime();

		return clock.sec.format("%02d");
	}
}

} // module Label
