// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.System;

module Element {

class Seconds extends Label {
	function initialize() {
		Label.initialize();

		self.styles = [
			new Element.Style(Font.TYPEFACE, Font.STYLE_REGULAR_THIN, 0xAAAAAA),
		];
	}

	function refresh() as Void {
		var clock = System.getClockTime();

		self.label = clock.sec.format("%02d");
	}
}

} // module Element
