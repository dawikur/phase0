// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Stress extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:stress),
				Resources.get(Rez.Strings.LABEL_STRESS)
			);

			self.value_max = 100;
		}

		function get_() as Lang.Number? {
			return SensorProvider.getSensorHistoryData(
				self.name,
				SensorHistory.getStressHistory({ :period => 1 })
			);
		}
	}
} // module Data
