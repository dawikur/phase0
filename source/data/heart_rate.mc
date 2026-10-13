// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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
				Data.RefreshRate.SEC
			);

			var current_sport = UserProfile.getCurrentSport();
			var zones = UserProfile.getHeartRateZones(current_sport);
			if (zones != null and 5 < zones.size()) {
				self.value_max = zones[5] as Lang.Number;
			}
		}

		function refresh() as Void {
			// Heart rate represents a live reading; never show a persisted value
			// after the sensor stops reporting.
			self.value = null;

			var activity_info = Activity.getActivityInfo();
			if (
				activity_info != null and
				activity_info.currentHeartRate != null and
				activity_info.currentHeartRate !=
					ActivityMonitor.INVALID_HR_SAMPLE
			) {
				self.value = activity_info.currentHeartRate;
			} else {
				if (SensorHistory has :getHeartRateHistory) {
					self.value = SensorProvider.getRaw(
						SensorHistory.getHeartRateHistory(
							SensorProvider.OPTIONS
						)
					);
				}
			}
		}
	}
} // module Data
