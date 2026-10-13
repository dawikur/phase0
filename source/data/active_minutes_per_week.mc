// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class ActiveMinutesPerWeek extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INTENSITY_MINUTES
					: null,
				Resources.get(Rez.Strings.LABEL_ACTIVE_MINUTES_PER_WEEK),
				Data.RefreshRate.MIN
			);

			var info = ActivityMonitor.getInfo();
			if (info has :activeMinutesWeekGoal) {
				self.value_max = info.activeMinutesWeekGoal;
			}
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			var active_minutes =
				info has :activeMinutesWeek ? info.activeMinutesWeek : null;
			self.value = active_minutes != null ? active_minutes.total : null;
		}
	}
} // module Data
