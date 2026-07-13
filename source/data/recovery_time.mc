// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class RecoveryTime extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:recovery_time),
				Resources.get(Rez.Strings.LABEL_RECOVERY_TIME)
			);
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().timeToRecovery;
		}
	}
} // module Data
