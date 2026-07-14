// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Steps extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_STEPS
					: null,
				Resources.get(Rez.Strings.LABEL_STEPS)
			);

			self.value_max = ActivityMonitor.getInfo().stepGoal;
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().steps;
		}
	}
} // module Data
