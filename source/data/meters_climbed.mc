// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class MetersClimbed extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_METERS_CLIMBED),
				RefreshRate.MIN
			);
		}

		function refresh() as Void {
			var info = ActivityMonitor.getInfo();
			var meters_climbed =
				info has :metersClimbed ? info.metersClimbed : null;
			self.value =
				meters_climbed != null
					? Units.convertElevation(meters_climbed.toNumber())
					: null;
		}
	}
} // module Data
