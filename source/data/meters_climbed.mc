// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class MetersClimbed extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"M Up",
			CATEGORY_VERTICAL,
			Fonts.ICON_NONE
		);
	}

	function get_() as Lang.Number or Null {
		var meters_climbed = ActivityMonitor.getInfo().metersClimbed;
		if (meters_climbed != null) {
			return Units.convertElevation(meters_climbed as Lang.Number);
		}
		return null;
	}
}

} // module Data
