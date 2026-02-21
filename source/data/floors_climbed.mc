// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class FloorsClimbed extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_FLOORS_CLIMBED,
			"Floors",
			CATEGORY_VERTICAL
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbed;
	}

	function getMax() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbedGoal;
	}
}

} // module Data
