// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class ActiveMinutesPerDay extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_ACTIVE_MINUTES_PER_DAY),
				RefreshRate.MIN
			);
		}

		function get_() as Lang.Number? {
			var active_minutes = ActivityMonitor.getInfo().activeMinutesDay;
			if (active_minutes != null) {
				return active_minutes.total;
			}
			return null;
		}
	}
} // module Data
