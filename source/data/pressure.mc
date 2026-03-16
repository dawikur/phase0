// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Pressure extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE,
			"Press",
			CATEGORY_SYSTEM,
			Font.ICON_NONE
		);
	}

	function getMaybe() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getPressureHistory({:period => 1})
		) as Lang.Number or Null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
