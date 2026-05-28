// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {

class MetersDescended extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.load(Rez.Strings.LABEL_METERS_DESCENDED),
			CATEGORY_VERTICAL
		);
	}

	function get_() as Lang.Number or Null {
		var meters_descended = ActivityMonitor.getInfo().metersDescended;
		if (meters_descended != null) {
			return Units.convertElevation(meters_descended as Lang.Number);
		}
		return null;
	}
}

} // module Data
