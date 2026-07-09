// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class MetersClimbed extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_INVALID,
				Resources.get(Rez.Strings.LABEL_METERS_CLIMBED)
			);
		}

		function get_() as Lang.Number? {
			var meters_climbed = ActivityMonitor.getInfo().metersClimbed;
			if (meters_climbed != null) {
				return Units.convertElevation(meters_climbed as Lang.Number);
			}
			return null;
		}
	}
} // module Data
