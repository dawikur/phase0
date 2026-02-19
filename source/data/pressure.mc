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
			"Pressure", // TODO
			Render.COLOR_BLUE
		);
	}

	function get() as Lang.Number or Null {
		var pressure_iterator = SensorHistory.getPressureHistory({:period => 1});
		if (pressure_iterator != null) {
			var pressure_maybe = pressure_iterator.next();
			if (pressure_maybe != null) {
				return pressure_maybe.data as Lang.Number;
			}
		}
		return null;
	}

	function getMax() as Lang.Number or Null {
		return 100;
	}
}

} // module Data
