// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.UserProfile;

module Field {

class HR extends Base {
	function initialize(_small as Lang.Boolean) {
		Base.initialize(_small);

		self.header_ = Application.loadResource(Rez.Strings.LABEL_HR) as Lang.String;
	}

	function getValue_() as Lang.Number or Null {
		var activity_info = Activity.getActivityInfo();
		if (activity_info != null) {
			var sample = activity_info.currentHeartRate;
			if(sample != null) {
				return sample;
			}
		}

		var history_it = ActivityMonitor.getHeartRateHistory(1, true);
		var history = history_it.next();
		if (history != null && history.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
			return history.heartRate;
		}

		return null;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var current_sport = UserProfile.getCurrentSport();
		var zones = UserProfile.getHeartRateZones(current_sport) as Lang.Array<Lang.Number>;

		self.max_value_ = zones[5] as Lang.Number;
	}
}

} // module Field
