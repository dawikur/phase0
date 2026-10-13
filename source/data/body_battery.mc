// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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
				Data.RefreshRate.MIN
			);

			self.value_max = 100;
			self.icon = Fonts.ICON_NONE;
		}

		function refresh() as Void {
			if (SensorHistory has :getBodyBatteryHistory) {
				self.value = SensorProvider.get(
					self.name,
					SensorHistory.getBodyBatteryHistory(SensorProvider.OPTIONS)
				);
			} else {
				self.value = null;
			}
			self.icon = batteryIcon(self.value);
		}
	}
} // module Data
