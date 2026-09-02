// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Pushes extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_WHEELCHAIR_PUSHES
					: null,
				Resources.get(Rez.Strings.LABEL_PUSHES),
				RefreshRate.MIN
			);

			self.value_max = ActivityMonitor.getInfo().pushGoal;
		}

		function refresh() as Void {
			self.value = ActivityMonitor.getInfo().pushes;
		}
	}
} // module Data
