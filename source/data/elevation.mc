// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Elevation extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_ALTITUDE,
			"Elev",
			CATEGORY_VERTICAL
		);
	}

	function getMaybe() as Lang.Number or Null {
		var elevation_iterator = SensorHistory.getElevationHistory({:period => 1});
		if (elevation_iterator != null) {
			var elevation_maybe = elevation_iterator.next();
			if (elevation_maybe != null) {
				return Units.convertElevation(elevation_maybe.data as Lang.Number);
			}
		}
		return null;
	}
}

} // module Data
