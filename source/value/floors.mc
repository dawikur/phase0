// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.ActivityMonitor;

module Value {

class Floors extends Base {
	function initialize() {
		Base.initialize();

		self.label = "Floors:";
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbed;
	}

	function getMax_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbedGoal;
	}
}

} // module Value
