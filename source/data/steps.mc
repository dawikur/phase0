// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class Steps extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_STEPS,
			"Steps",
			CATEGORY_MOVEMENT
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}

	function getMax() as Lang.Number or Null {
		return ActivityMonitor.getInfo().stepGoal;
	}
}

} // module Data
