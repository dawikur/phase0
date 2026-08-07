// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

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
			var meters_climbed = ActivityMonitor.getInfo().metersClimbed;
			self.value =
				meters_climbed != null
					? Units.convertElevation(meters_climbed.toNumber())
					: null;
		}
	}
} // module Data
