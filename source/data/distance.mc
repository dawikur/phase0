// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {

class Distance extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.load(Rez.Strings.LABEL_DISTANCE),
			CATEGORY_MOVEMENT
		);
	}

	function get_() as Lang.Number or Null {
		var distance_cm = ActivityMonitor.getInfo().distance;
		if (distance_cm != null) {
			return Units.convertDistance(distance_cm / 100);
		}
		return null;
	}
}

} // module Data
