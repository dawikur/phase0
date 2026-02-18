// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class ActiveMinutesDay extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Active Minutes/Day"; // TODO
	}

	function getValue() as Lang.Number or Null {
		var active_minutes = ActivityMonitor.getInfo().activeMinutesDay;
		if (active_minutes != null) {
			return active_minutes.total;
		}
		return null;
	}
}

} // module Complication
