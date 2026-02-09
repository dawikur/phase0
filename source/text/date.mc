// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

module Text {

class Date extends Base {
	function initialize() {
		Base.initialize();
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);

		self.label_ = Lang.format("$1$ $2$ $3$", [
			Application.loadResource(Resources.DAYS_OF_WEEK[now.day_of_week as Lang.Number]) as Lang.String,
			now.day.format("%02d"),
			Application.loadResource(Resources.MONTHS[now.month as Lang.Number]) as Lang.String,
		]);
	}
}

} // module Text
