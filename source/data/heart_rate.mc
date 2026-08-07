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
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_HEART_RATE
					: null,
				Resources.get(Rez.Strings.LABEL_HEART_RATE),
				RefreshRate.SEC
			);

			var current_sport = UserProfile.getCurrentSport();
			var zones = UserProfile.getHeartRateZones(current_sport);
			if (zones != null and 5 < zones.size()) {
				self.value_max = zones[5] as Lang.Number;
			}
		}

		function refresh() as Void {
			var activity_info = Activity.getActivityInfo();
			if (
				activity_info != null and
				activity_info.currentHeartRate != null
			) {
				self.value = activity_info.currentHeartRate;
			} else {
				self.value = SensorProvider.get(
					self.name,
					SensorHistory.getHeartRateHistory(SensorProvider.OPTIONS)
				);
			}
		}
	}
} // module Data
