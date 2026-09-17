// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Pressure extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE
					: null,
				Resources.get(Rez.Strings.LABEL_PRESSURE),
				RefreshRate.MIN
			);

			self.value_max = 100;
		}

		function refresh() as Void {
			if (SensorHistory has :getPressureHistory) {
				self.value = SensorProvider.get(
					self.name,
					SensorHistory.getPressureHistory(SensorProvider.OPTIONS)
				);
			} else {
				self.value = null;
			}
		}
	}
} // module Data
