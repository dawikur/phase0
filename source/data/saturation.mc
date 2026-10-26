// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	(:data_gauge)
	class Saturation extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_PULSE_OX
					: null,
				Resources.get(Rez.Strings.LABEL_SATURATION),
				Data.RefreshRate.MIN
			);

			self.value_max = 100;
		}

		function refresh() as Void {
			if (SensorHistory has :getOxygenSaturationHistory) {
				self.value = SensorProvider.get(
					self.name,
					SensorHistory.getOxygenSaturationHistory(
						SensorProvider.OPTIONS
					)
				);
			} else {
				self.value = null;
			}
		}
	}
} // module Data
