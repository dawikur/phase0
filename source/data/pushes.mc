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
			Font.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().pushes;
	}

	function getMax() as Lang.Number or Null {
		return ActivityMonitor.getInfo().pushGoal;
	}
}

} // module Data
