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
			"HR",
			CATEGORY_PHYSIOLOGICAL,
			Fonts.ICON_NONE
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
			SensorHistory.getStressHistory({:period => 1})
		) as Lang.Number or Null;
	}
}

} // module Data
