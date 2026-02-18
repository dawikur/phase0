// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class Steps extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_STEPS);

		self.label_ = Application.loadResource(Rez.Strings.LABEL_STEPS) as Lang.String;
	}

	function getValue() as Lang.Number or Null {
		return ActivityMonitor.getInfo().steps;
	}

	function getValueMax() as Lang.Number or Null {
		return ActivityMonitor.getInfo().stepGoal;
	}
}

} // module Complication
