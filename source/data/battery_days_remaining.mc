// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

module Data {
	class BatteryDaysRemaining extends Base {
		function initialize() {
			Base.initialize(
				Base.Complication(:battery),
				Resources.get(Rez.Strings.LABEL_BATTERY_DAYS_REMAINING)
			);
		}

		function get_() as Lang.Number? {
			return System.getSystemStats().batteryInDays.toNumber();
		}
	}
} // module Data
