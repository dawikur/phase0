// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Temperature extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE
					: null,
				Resources.get(Rez.Strings.LABEL_TEMPERATURE),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			if (SensorHistory has :getTemperatureHistory) {
				self.value = SensorProvider.get(
					self.name,
					SensorHistory.getTemperatureHistory(SensorProvider.OPTIONS)
				);
			} else {
				self.value = null;
			}
		}
	}
} // module Data
