// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Distance extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Dist",
			CATEGORY_MOVEMENT,
			Font.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		var distance_cm = ActivityMonitor.getInfo().distance;
		if (distance_cm != null) {
			return Units.convertDistance(distance_cm / 100);
		}
		return null;
	}
}

} // module Data
