// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class Stress extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_STRESS);

		self.label_ = "Stress"; // TODO
	}

	function getValue() as Lang.Number or Null {
		return ActivityMonitor.getInfo().stressScore;
	}

	function getValueMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Complication
