// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module Label {

class Date extends Base {
	function initialize() {
		Base.initialize();

		self.styles_ = [
			new Label.Style(Font.DOT_REGULAR, 0x555555),
			new Label.Style(Font.DOT_REGULAR_THIN, 0xAAAAAA),
		];
		self.justify_ = Graphics.TEXT_JUSTIFY_LEFT;
	}

	function get_() as Lang.String {
		var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);

		return Lang.format("$1$ $2$ $3$", [
			Application.loadResource(Resources.DAYS_OF_WEEK[now.day_of_week as Lang.Number]) as Lang.String,
			now.day.format("%02d"),
			Application.loadResource(Resources.MONTHS[now.month as Lang.Number]) as Lang.String,
		]);
	}
}

} // module Label
