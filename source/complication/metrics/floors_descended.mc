// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Complication {

class FloorsDescended extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_INVALID);

		self.label_ = "Floors Desc"; // TODO
	}

	function getValue() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsDescended;
	}
}

} // module Complication
