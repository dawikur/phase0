// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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
				Resources.get(Rez.Strings.LABEL_MOVE_BAR),
				RefreshRate.MIN
			);

			self.value_max = ActivityMonitor.MOVE_BAR_LEVEL_MAX;
		}

		function defaultWidth() as Lang.Number {
			return 1;
		}

		function refresh() as Void {
			self.value = ActivityMonitor.getInfo().moveBarLevel;
		}
	}
} // module Data
