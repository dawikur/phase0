// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class ActiveMinutesPerDay extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_ACTIVE_MINUTES_PER_DAY),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			var active_minutes =
				info has :activeMinutesDay ? info.activeMinutesDay : null;
			self.value = active_minutes != null ? active_minutes.total : null;
		}
	}
} // module Data
