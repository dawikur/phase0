// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class RecoveryTime extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_RECOVERY_TIME
					: null,
				Resources.get(Rez.Strings.LABEL_RECOVERY_TIME),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			self.value = ActivityMonitor.getInfo().timeToRecovery;
		}
	}
} // module Data
