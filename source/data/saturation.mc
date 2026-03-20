// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Saturation extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_PULSE_OX,
			"SPO2",
			CATEGORY_PHYSIOLOGICAL,
			Fonts.ICON_NONE
		);
	}

	function getMaybe() as Lang.Number or Null {
		return self.getSensorHistoryData_(
			SensorHistory.getOxygenSaturationHistory({:period => 1})
		) as Lang.Number or Null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
