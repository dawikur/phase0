// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class PushDistance extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Push D",
			CATEGORY_MOVEMENT,
			Fonts.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		var distance_cm = ActivityMonitor.getInfo().pushDistance;
		if (distance_cm != null) {
			return Units.convertDistance(distance_cm / 100);
		}
		return null;
	}
}

} // module Data
