// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Element {

class Seconds extends Label {
	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	function initialize() {
		Label.initialize();

		self.styles = [
			new Element.Style(Font.DOT_REGULAR_THIN, 0xAAAAAA),
		];
	}

	function get_() as Lang.String {
		var clock = System.getClockTime();

		return clock.sec.format("%02d");
	}
}

} // module Element
