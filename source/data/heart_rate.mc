// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class HeartRate extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_HEART_RATE,
			Application.loadResource(Rez.Strings.LABEL_HR) as Lang.String,
			Render.COLOR_RED
		);
	}

	function get() as Lang.Number or Null {
		var activity_info = Activity.getActivityInfo();
		if (activity_info != null) {
			if (activity_info.currentHeartRate != null) {
				return activity_info.currentHeartRate;
			}
		}

		var history_iterator = ActivityMonitor.getHeartRateHistory(1, true);
		var history_sample = history_iterator.next();
		if (history_sample != null and history_sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
			if (history_sample.heartRate != null) {
				return 300 + history_sample.heartRate as Lang.Number;
			}
		}

		return null;
	}

	function getMax() as Lang.Number or Null {
		var current_sport = UserProfile.getCurrentSport();
		var zones = UserProfile.getHeartRateZones(current_sport) as Lang.Array<Lang.Number>;

		return zones[5] as Lang.Number;
	}
}

} // module Data
