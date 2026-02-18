// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class PushDistance extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Push Distance"; // TODO
	}

	function getValue() as Lang.Number or Null {
		// TODO: this is in centimeters, convertion to ft
		return ActivityMonitor.getInfo().pushDistance;
	}
}

} // module Complication
