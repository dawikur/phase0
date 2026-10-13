// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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
				Data.RefreshRate.MIN
			);
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			self.value = info has :floorsDescended ? info.floorsDescended : null;
		}
	}
} // module Data
