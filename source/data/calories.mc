// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class Calories extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_CALORIES,
			"Cal",
			CATEGORY_ENERGY,
			Font.ICON_NONE
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().calories;
	}
}

} // module Data
