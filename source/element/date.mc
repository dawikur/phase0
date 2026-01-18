// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module Element {

class Date extends Label {
	function initialize() {
		Label.initialize();

		self.styles = [
			new Element.Style(Font.TYPEFACE, Font.STYLE_REGULAR, 0x555555),
			new Element.Style(Font.TYPEFACE, Font.STYLE_REGULAR_THIN, 0xAAAAAA),
		];
	}

	function refresh() as Void {
		var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);

		self.label = $.join(" ", [
			Resources.DAYS_OF_WEEK[now.day_of_week as Lang.Number],
			now.day.format("%02d"),
			Resources.MONTHS[now.month as Lang.Number],
		]);
	}
}

} // module Element
