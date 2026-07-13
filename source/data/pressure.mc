// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

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
				Base.Complication(:pressure),
				Resources.get(Rez.Strings.LABEL_PRESSURE)
			);

			self.value_max = 100;
		}

		function get_() as Lang.Number? {
			return SensorProvider.getSensorHistoryData(
				self.name,
				SensorHistory.getPressureHistory({ :period => 1 })
			);
		}
	}
} // module Data
