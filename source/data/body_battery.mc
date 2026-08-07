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
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_BODY_BATTERY
					: null,
				Resources.get(Rez.Strings.LABEL_BODY_BATTERY),
				RefreshRate.MIN
			);

			self.value_max = 100;
		}

		function refresh() as Void {
			self.value = SensorProvider.get(
				self.name,
				SensorHistory.getBodyBatteryHistory(SensorProvider.OPTIONS)
			);
		}
	}
} // module Data
