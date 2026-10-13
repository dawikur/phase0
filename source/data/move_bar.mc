// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class MoveBar extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_MOVE_BAR),
				Data.RefreshRate.MIN
			);

			self.value_max = ActivityMonitor.MOVE_BAR_LEVEL_MAX;
			self.icon = moveBarIcon(null);
		}

		function defaultWidth() as Lang.Number {
			return 1;
		}

		function refresh() as Void {
			self.value = ActivityMonitor.getInfo().moveBarLevel;
			self.icon = moveBarIcon(self.value);
		}
	}
} // module Data
