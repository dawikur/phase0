// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Pushes extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_WHEELCHAIR_PUSHES,
				Resources.get(Rez.Strings.LABEL_PUSHES),
				CATEGORY_MOVEMENT
			);

			self.value_max = ActivityMonitor.getInfo().pushGoal;
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().pushes;
		}
	}
} // module Data
