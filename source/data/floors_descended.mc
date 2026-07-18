// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class FloorsDescended extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_FLOORS_DESCENDED),
				RefreshRate.MIN
			);
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().floorsDescended;
		}
	}
} // module Data
