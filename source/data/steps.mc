// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	(:data_gauge)
	class Steps extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_STEPS
					: null,
				Resources.get(Rez.Strings.LABEL_STEPS),
				Data.RefreshRate.MIN
			);

			self.value_max = ActivityMonitor.getInfo().stepGoal;
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			self.value = info.steps;
			self.value_max = info.stepGoal;
		}
	}
} // module Data
