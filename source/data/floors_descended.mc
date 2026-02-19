// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.Complications;

module Data {

class FloorsDescended extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Floors Desc", // TODO
			Render.COLOR_MAGENTA
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().floorsDescended;
	}
}

} // module Data
