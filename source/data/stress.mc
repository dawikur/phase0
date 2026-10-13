// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Stress extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_STRESS
					: null,
				Resources.get(Rez.Strings.LABEL_STRESS),
				Data.RefreshRate.MIN
			);

			self.value_max = 100;
		}

		function refresh() as Void {
			if (SensorHistory has :getStressHistory) {
				self.value = SensorProvider.get(
					self.name,
					SensorHistory.getStressHistory(SensorProvider.OPTIONS)
				);
			} else {
				self.value = null;
			}
		}
	}
} // module Data
