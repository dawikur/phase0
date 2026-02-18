// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class MetersDescended extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Meters Descended"; // TODO
	}

	function getValue() as Lang.Number or Null {
		// TODO: this is in meters, convertion to ft
		var meters_descended = ActivityMonitor.getInfo().metersDescended;
		if (meters_descended != null) {
			return meters_descended.toNumber();
		}
		return null;
	}
}

} // module Complication
