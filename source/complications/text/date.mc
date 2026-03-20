// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

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
			Resources.loadDayOfWeek(now.day_of_week as Lang.Number),
			now.day.format("%02d"),
			Resources.loadMonth(now.month as Lang.Number)
		]);
	}
}

} // module Complication
