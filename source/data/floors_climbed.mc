// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class FloorsClimbed extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_FLOORS_CLIMBED
					: null,
				Resources.get(Rez.Strings.LABEL_FLOORS_CLIMBED),
				RefreshRate.MIN
			);

			var info = ActivityMonitor.getInfo();
			if (info has :floorsClimbedGoal) {
				self.value_max = info.floorsClimbedGoal;
			}
		}

		function refresh() as Void {
			self.value = ActivityMonitor.getInfo().floorsClimbed;
		}
	}
} // module Data
