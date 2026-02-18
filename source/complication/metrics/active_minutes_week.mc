// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class ActiveMinutesWeek extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INTENSITY_MINUTES);

		self.label_ = "Active Minutes/Week"; // TODO
	}

	function getValue() as Lang.Number or Null {
		var active_minutes = ActivityMonitor.getInfo().activeMinutesWeek;
		if (active_minutes != null) {
			return active_minutes.total;
		}
		return null;
	}

	function getValueMax() as Lang.Number or Null {
		return ActivityMonitor.getInfo().activeMinutesWeekGoal;
	}
}

} // module Complication
