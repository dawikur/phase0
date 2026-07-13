// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	class HeartRate extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:heart_rate),
				Resources.get(Rez.Strings.LABEL_HEART_RATE)
			);

			var current_sport = UserProfile.getCurrentSport();
			var zones = UserProfile.getHeartRateZones(current_sport);
			if (zones != null and 5 < zones.size()) {
				self.value_max = zones[5] as Lang.Number;
			}
		}

		function get_() as Lang.Number? {
			var activity_info = Activity.getActivityInfo();
			if (activity_info != null) {
				if (activity_info.currentHeartRate != null) {
					return activity_info.currentHeartRate;
				}
			}

			return SensorProvider.getSensorHistoryData(
				self.name,
				SensorHistory.getHeartRateHistory({ :period => 1 })
			);
		}
	}
} // module Data
