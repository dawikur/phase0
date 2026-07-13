// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class BodyBattery extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:body_battery),
				Resources.get(Rez.Strings.LABEL_BODY_BATTERY)
			);

			self.value_max = 100;
		}

		function get_() as Lang.Number? {
			return SensorProvider.getSensorHistoryData(
				self.name,
				SensorHistory.getBodyBatteryHistory({ :period => 1 })
			);
		}
	}
} // module Data
