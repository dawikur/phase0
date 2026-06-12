// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {

class Calories extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_CALORIES,
			Resources.get(Rez.Strings.LABEL_CALORIES),
			CATEGORY_ENERGY
		);
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().calories;
	}
}

} // module Data
