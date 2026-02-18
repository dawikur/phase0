// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class Pushes extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_WHEELCHAIR_PUSHES);

		self.label_ = "Pushes"; // TODO
	}

	function getValue() as Lang.Number or Null {
		return ActivityMonitor.getInfo().pushes;
	}

	function getValueMax() as Lang.Number or Null {
		return ActivityMonitor.getInfo().pushGoal;
	}
}

} // module Complication
