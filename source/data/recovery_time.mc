// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {

class RecoveryTime extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_RECOVERY_TIME,
			Resources.load(Rez.Strings.LABEL_RECOVERY_TIME),
			CATEGORY_RECOVERY
		);
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().timeToRecovery;
	}
}

} // module Data
