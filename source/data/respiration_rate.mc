// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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

		function defaultWidth() as Lang.Number {
			return 2;
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			self.value =
				info has :respirationRate ? info.respirationRate : null;
		}
	}
} // module Data
