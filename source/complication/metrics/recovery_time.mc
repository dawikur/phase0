// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class RecoveryTime extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_RECOVERY_TIME);

		self.label_ = "Recovery Time"; // TODO
	}

	function getValue() as Lang.Number or Null {
		return ActivityMonitor.getInfo().timeToRecovery;
	}
}

} // module Complication
