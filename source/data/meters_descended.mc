// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class MetersDescended extends Base {
		function initialize() {
			Base.initialize(
				null,
				Resources.get(Rez.Strings.LABEL_METERS_DESCENDED)
			);
		}

		function get_() as Lang.Number? {
			var meters_descended = ActivityMonitor.getInfo().metersDescended;
			if (meters_descended != null) {
				return Units.convertElevation(meters_descended as Lang.Number);
			}
			return null;
		}
	}
} // module Data
