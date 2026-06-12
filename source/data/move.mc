// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {

class Move extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.get(Rez.Strings.LABEL_MOVE),
			CATEGORY_PHYSIOLOGICAL
		);

		self.value_max = ActivityMonitor.MOVE_BAR_LEVEL_MAX;
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().moveBarLevel;
	}
}

} // module Data
