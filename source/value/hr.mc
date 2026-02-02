// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.ActivityMonitor;
import Toybox.UserProfile;

module Value {

class HR extends Base {
	function initialize() {
		Base.initialize();

		self.label = Application.loadResource(Rez.Strings.LABEL_HR) as Lang.String;
	}

	function get_() as Lang.Number or Null {
		var history = ActivityMonitor.getHeartRateHistory(1, true);
		var value = history.getMax();
		if (value != null && value != ActivityMonitor.INVALID_HR_SAMPLE) {
			return null;
		}
		return null;
	}

	function getMax_() as Lang.Number or Null {
		var current_sport = UserProfile.getCurrentSport();
		var zones = UserProfile.getHeartRateZones(current_sport) as Lang.Array<Lang.Number>;
		return zones[5] as Lang.Number;
	}
}

} // module Value
