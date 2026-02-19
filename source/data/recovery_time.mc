// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class RecoveryTime extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_RECOVERY_TIME,
			"Recovery Time", // TODO
			Render.COLOR_YELLOW
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().timeToRecovery;
	}
}

} // module Data
