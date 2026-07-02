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
				Complications.COMPLICATION_TYPE_BODY_BATTERY,
				Resources.get(Rez.Strings.LABEL_BODY_BATTERY),
				CATEGORY_RECOVERY
			);

			self.value_max = 100;
		}

		function getMaybe_() as Lang.Number? {
			return (
				self.getSensorHistoryData_(
					SensorHistory.getBodyBatteryHistory({ :period => 1 })
				) as Lang.Number?
			);
		}
	}
} // module Data
