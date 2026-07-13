// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Pushes extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:pushes),
				Resources.get(Rez.Strings.LABEL_PUSHES)
			);

			self.value_max = ActivityMonitor.getInfo().pushGoal;
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().pushes;
		}
	}
} // module Data
