// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class ActiveMinutesWeek extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INTENSITY_MINUTES,
			"Act/W",
			CATEGORY_MOVEMENT,
			Fonts.ICON_NONE
		);

		self.value_max = ActivityMonitor.getInfo().activeMinutesWeekGoal;
	}

	function get_() as Lang.Number or Null {
		var active_minutes = ActivityMonitor.getInfo().activeMinutesWeek;
		if (active_minutes != null) {
			return active_minutes.total;
		}
		return null;
	}
}

} // module Data
