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
			Complications.COMPLICATION_TYPE_HEART_RATE,
			Resources.get(Rez.Strings.LABEL_HEART_RATE),
			CATEGORY_PHYSIOLOGICAL
		);

		var current_sport = UserProfile.getCurrentSport();
		var zones =
			UserProfile.getHeartRateZones(current_sport) as Lang.Array<Lang.Number>;
		self.value_max = zones[5] as Lang.Number;
	}

	function get_() as Lang.Number or Null {
		var activity_info = Activity.getActivityInfo();
		if (activity_info != null) {
			if (activity_info.currentHeartRate != null) {
				return activity_info.currentHeartRate;
			}
		}

		return self.getSensorHistoryData_(
			SensorHistory.getHeartRateHistory({:period => 1})
		) as Lang.Number or Null;
	}
}

} // module Data
