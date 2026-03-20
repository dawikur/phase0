// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Stress extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_STRESS,
			"Strs",
			CATEGORY_ENERGY,
			Fonts.ICON_NONE
		);
	}

	function getMaybe() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getHeartRateHistory({:period => 1})
		) as Lang.Number or Null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
