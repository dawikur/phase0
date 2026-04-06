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
			Resources.load(Rez.Strings.LABEL_PRESSURE),
			CATEGORY_SYSTEM,
			Fonts.ICON_NONE
		);

		self.value_max = 100;
	}

	function getMaybe_() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getPressureHistory({:period => 1})
		) as Lang.Number or Null;
	}
}

} // module Data
