// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class RespirationRate extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_RESPIRATION_RATE
					: null,
				Resources.get(Rez.Strings.LABEL_RESPIRATION_RATE),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			self.value = ActivityMonitor.getInfo().respirationRate;
		}
	}
} // module Data
