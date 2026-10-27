// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	(:data_gauge)
	class FloorsClimbed extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_FLOORS_CLIMBED
					: null,
				Resources.get(Rez.Strings.LABEL_FLOORS_CLIMBED),
				Data.RefreshRate.MIN
			);

			var info = ActivityMonitor.getInfo();
			if (info has :floorsClimbedGoal) {
				self.value_max = info.floorsClimbedGoal;
			}
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			self.value_max = info has :floorsClimbedGoal
				? info.floorsClimbedGoal
				: null;
			self.value = info has :floorsClimbed ? info.floorsClimbed : null;
		}
	}
} // module Data
