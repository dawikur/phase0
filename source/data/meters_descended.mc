// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class MetersDescended extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"M Dn",
			CATEGORY_VERTICAL,
			Fonts.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		var meters_descended = ActivityMonitor.getInfo().metersDescended;
		if (meters_descended != null) {
			return Units.convertElevation(meters_descended as Lang.Number);
		}
		return null;
	}
}

} // module Data
