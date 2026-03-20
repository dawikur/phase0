// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;
import Toybox.SensorHistory;

module Data {

class BodyBattery extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_BODY_BATTERY,
			"Body",
			CATEGORY_RECOVERY,
			Fonts.ICON_NONE
		);
	}

	function getMaybe() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getBodyBatteryHistory({:period => 1})
		) as Lang.Number or Null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
