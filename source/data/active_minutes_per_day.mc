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
			var active_minutes = ActivityMonitor.getInfo().activeMinutesDay;
			self.value = active_minutes != null ? active_minutes.total : null;
		}
	}
} // module Data
