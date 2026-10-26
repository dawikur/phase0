// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	(:data_gauge)
	class Pushes extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_WHEELCHAIR_PUSHES
					: null,
				Resources.get(Rez.Strings.LABEL_PUSHES),
				Data.RefreshRate.MIN
			);

			var info = ActivityMonitor.getInfo();
			if (info has :pushGoal) {
				self.value_max = info.pushGoal;
			}
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			self.value = info has :pushes ? info.pushes : null;
		}
	}
} // module Data
