// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Complication {

class HeartRate extends Metric {
	function initialize() {
		Metric.initialize(Complications.COMPLICATION_TYPE_HEART_RATE);

		self.label_ = Application.loadResource(Rez.Strings.LABEL_HR) as Lang.String;
	}

	function getValue() as Lang.Number or Null {
		var activity_info = Activity.getActivityInfo();
		if (activity_info != null) {
			var sample = activity_info.currentHeartRate;
			if(sample != null) {
				return sample;
			}
		}

		var history_it = ActivityMonitor.getHeartRateHistory(1, true);
		var history = history_it.next();
		if (history != null and history.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
			return history.heartRate;
		}

		return null;
	}

	function getValueMax() as Lang.Number or Null {
		var current_sport = UserProfile.getCurrentSport();
		var zones = UserProfile.getHeartRateZones(current_sport) as Lang.Array<Lang.Number>;

		return zones[5] as Lang.Number;
	}
}

} // module Complication
