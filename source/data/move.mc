// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Move extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			"Move", // TODO
			Render.COLOR_RED
		);
	}

	function get() as Lang.Number or Null {
		return ActivityMonitor.getInfo().moveBarLevel;
	}

	function getMax() as Lang.Number or Null {
		return ActivityMonitor.MOVE_BAR_LEVEL_MAX;
	}
}

} // module Data
