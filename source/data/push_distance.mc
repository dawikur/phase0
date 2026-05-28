// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {

class PushDistance extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.load(Rez.Strings.LABEL_PUSH_DISTANCE),
			CATEGORY_MOVEMENT
		);
	}

	function get_() as Lang.Number or Null {
		var distance_cm = ActivityMonitor.getInfo().pushDistance;
		if (distance_cm != null) {
			return Units.convertDistance(distance_cm / 100);
		}
		return null;
	}
}

} // module Data
