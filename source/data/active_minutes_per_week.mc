// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class ActiveMinutesPerWeek extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:active_minutes_per_week),
				Resources.get(Rez.Strings.LABEL_ACTIVE_MINUTES_PER_WEEK)
			);

			self.value_max = ActivityMonitor.getInfo().activeMinutesWeekGoal;
		}

		function get_() as Lang.Number? {
			var active_minutes = ActivityMonitor.getInfo().activeMinutesWeek;
			if (active_minutes != null) {
				return active_minutes.total;
			}
			return null;
		}
	}
} // module Data
