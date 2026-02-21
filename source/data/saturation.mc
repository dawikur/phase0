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
			CATEGORY_PHYSIOLOGICAL
		);
	}

	function get() as Lang.Number or Null {
		var oxygen_saturation_iterator = SensorHistory.getOxygenSaturationHistory({:period => 1});
		if (oxygen_saturation_iterator != null) {
			var oxygen_saturation_maybe = oxygen_saturation_iterator.next();
			if (oxygen_saturation_maybe != null) {
				return oxygen_saturation_maybe.data as Lang.Number;
			}
		}
		return null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
