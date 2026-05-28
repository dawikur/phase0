// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {

class Steps extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_STEPS,
			Resources.load(Rez.Strings.LABEL_STEPS),
			CATEGORY_MOVEMENT
		);

		self.value_max = ActivityMonitor.getInfo().stepGoal;
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}
}

} // module Data
