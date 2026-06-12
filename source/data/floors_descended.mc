// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {

class FloorsDescended extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.get(Rez.Strings.LABEL_FLOORS_DESCENDED),
			CATEGORY_VERTICAL
		);
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsDescended;
	}
}

} // module Data
