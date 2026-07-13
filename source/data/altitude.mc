// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class Altitude extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:altitude),
				Resources.get(Rez.Strings.LABEL_ALTITUDE)
			);
		}

		function get_() as Lang.Number? {
			return SensorProvider.getSensorHistoryData(
				self.name,
				SensorHistory.getElevationHistory({ :period => 1 })
			);
		}
	}
} // module Data
