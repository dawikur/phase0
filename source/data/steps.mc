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
			CATEGORY_MOVEMENT,
			Fonts.ICON_NONE
		);

		self.value_max = ActivityMonitor.getInfo().stepGoal;
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}
}

} // module Data
