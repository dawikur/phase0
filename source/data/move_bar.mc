// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.UserProfile;

module Data {
	class MoveBar extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_MOVE_BAR)
			);

			self.value_max = ActivityMonitor.MOVE_BAR_LEVEL_MAX;
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().moveBarLevel;
		}
	}
} // module Data
