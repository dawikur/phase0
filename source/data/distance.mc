// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class Distance extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_DISTANCE),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			var distance_cm = ActivityMonitor.getInfo().distance;
			self.value =
				distance_cm != null
					? Units.convertDistance(distance_cm / 100)
					: null;
		}
	}
} // module Data
