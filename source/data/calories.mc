// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Calories extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CALORIES
					: null,
				Resources.get(Rez.Strings.LABEL_CALORIES),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			self.value = ActivityMonitor.getInfo().calories;
		}
	}
} // module Data
