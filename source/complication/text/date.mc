// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Time;

module Complication {

class Date extends Text {
	function initialize() {
		Text.initialize(Complications.COMPLICATION_TYPE_DATE);
	}

	hidden function getValue() as Lang.String {
		var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);

		return Lang.format("$1$ $2$ $3$", [
			Application.loadResource(Resources.DAYS_OF_WEEK[now.day_of_week as Lang.Number]) as Lang.String,
			now.day.format("%02d"),
			Application.loadResource(Resources.MONTHS[now.month as Lang.Number]) as Lang.String,
		]);
	}
}

} // module Complication
