// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class Distance extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Distance"; // TODO
	}

	function getValue() as Lang.Number or Null {
		// TODO: this is in centimeters, convertion to ft
		return ActivityMonitor.getInfo().distance;
	}
}

} // module Complication
