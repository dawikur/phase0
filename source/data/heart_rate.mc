// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.UserProfile;

module Data {
	(:data_gauge)
	class HeartRate extends Base {
		hidden var last_zones_minute_ as Lang.Number = -1;

		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_HEART_RATE
					: null,
				Resources.get(Rez.Strings.LABEL_HEART_RATE),
				Data.RefreshRate.SEC
			);

			self.refreshZones_();
		}

		hidden function refreshZones_() as Void {
			var seconds = Runtime.now.value();
			var minute = (seconds - (seconds % 60)) / 60;
			if (self.last_zones_minute_ == minute) {
				return;
			}
			self.last_zones_minute_ = minute;
			var current_sport = UserProfile.getCurrentSport();
			var zones = UserProfile.getHeartRateZones(current_sport);
			self.value_max =
				zones != null and 5 < zones.size()
					? zones[5] as Lang.Number
					: null;
		}

		function refresh() as Void {
			self.refreshZones_();

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
