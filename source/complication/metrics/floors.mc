// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class Floors extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_FLOORS_CLIMBED);

		self.label_ = Application.loadResource(Rez.Strings.LABEL_FLOORS) as Lang.String;
	}

	hidden function getValue_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbed;
	}

	hidden function getValueMax_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsClimbedGoal;
	}
}

} // module Complication
