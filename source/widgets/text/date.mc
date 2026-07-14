// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.Time;

module Widgets {
	class Date extends Text {
		function initialize() {
			Text.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_DATE
					: null
			);
		}

		hidden function getValue() as Lang.String {
			var now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);

			return Lang.format("$1$ $2$ $3$", [
				Resources.getDayOfWeek(now.day_of_week as Lang.Number),
				now.day.format("%02d"),
				Resources.getMonth(now.month as Lang.Number),
			]);
		}
	}
} // module Widgets
