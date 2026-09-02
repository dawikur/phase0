// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class MetersDescended extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_METERS_DESCENDED),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			var meters_descended = ActivityMonitor.getInfo().metersDescended;
			self.value =
				meters_descended != null
					? Units.convertElevation(meters_descended.toNumber())
					: null;
		}
	}
} // module Data
