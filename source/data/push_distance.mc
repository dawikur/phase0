// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class PushDistance extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_PUSH_DISTANCE),
				RefreshRate.MIN
			);
		}

		function get_() as Lang.Number? {
			var distance_cm = ActivityMonitor.getInfo().pushDistance;
			if (distance_cm != null) {
				return Units.convertDistance(distance_cm / 100);
			}
			return null;
		}
	}
} // module Data
