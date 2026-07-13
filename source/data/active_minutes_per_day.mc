// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class ActiveMinutesPerDay extends Base {
		function initialize() {
			Base.initialize(
				null,
				Resources.get(Rez.Strings.LABEL_ACTIVE_MINUTES_PER_DAY)
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
