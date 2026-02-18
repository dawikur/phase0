// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class MetersClimbed extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Meters Climbed"; // TODO
	}

	function getValue() as Lang.Number or Null {
		// TODO: this is in meters, convertion to ft
		var meters_climbed = ActivityMonitor.getInfo().metersClimbed;
		if (meters_climbed != null) {
			return meters_climbed.toNumber();
		}
		return null;
	}
}

} // module Complication
