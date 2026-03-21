// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class Pushes extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_WHEELCHAIR_PUSHES,
			"Push",
			CATEGORY_MOVEMENT,
			Fonts.ICON_NONE
		);

		self.value_max = ActivityMonitor.getInfo().pushGoal;
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().pushes;
	}
}

} // module Data
