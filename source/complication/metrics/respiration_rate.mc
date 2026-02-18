// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class RespirationRate extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_RESPIRATION_RATE);

		self.label_ = "Respiration Rate"; // TODO
	}

	function getValue() as Lang.Number or Null {
		return ActivityMonitor.getInfo().respirationRate;
	}
}

} // module Complication
