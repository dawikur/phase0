// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.UserProfile;
import Toybox.Complications;

module Data {

class Move extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.load(Rez.Strings.LABEL_MOVE),
			CATEGORY_PHYSIOLOGICAL,
			Fonts.ICON_NONE
		);

		self.value_max = ActivityMonitor.MOVE_BAR_LEVEL_MAX;
	}

	function get_() as Lang.Number or Null {
		return ActivityMonitor.getInfo().moveBarLevel;
	}
}

} // module Data
