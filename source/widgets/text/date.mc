// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;

module Widgets {
	class Date extends Text {
		function initialize() {
			Text.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_DATE
					: null,
				RefreshRate.HOUR
			);
		}

		function getValue() as Lang.String {
			var now = Runtime.now_info;

			return Lang.format("$1$ $2$ $3$", [
				Resources.getDayOfWeek(now.day_of_week as Lang.Number),
				now.day.format("%02d"),
				Resources.getMonth(now.month as Lang.Number),
			]);
		}
	}
} // module Widgets
