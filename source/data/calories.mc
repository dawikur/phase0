// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Calories extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:calories),
				Resources.get(Rez.Strings.LABEL_CALORIES)
			);
		}

		function get_() as Lang.Number? {
			return ActivityMonitor.getInfo().calories;
		}
	}
} // module Data
