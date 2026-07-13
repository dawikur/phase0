// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class FloorsClimbed extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:floors_climbed),
				Resources.get(Rez.Strings.LABEL_FLOORS_CLIMBED)
			);

			self.value_max = ActivityMonitor.getInfo().floorsClimbedGoal;
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().floorsClimbed;
		}
	}
} // module Data
