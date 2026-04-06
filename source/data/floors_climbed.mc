// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class FloorsClimbed extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_FLOORS_CLIMBED,
			Resources.load(Rez.Strings.LABEL_FLOORS_CLIMBED),
			CATEGORY_VERTICAL,
			Fonts.ICON_NONE
		);

		self.value_max = ActivityMonitor.getInfo().floorsClimbedGoal;
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbed;
	}
}

} // module Data
