// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

module Data {
	class BatteryDaysRemaining extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_BATTERY
					: null,
				Resources.get(Rez.Strings.LABEL_BATTERY_DAYS_REMAINING),
				RefreshRate.SEC
			);
		}

		function refresh() as Void {
			self.value = System.getSystemStats().batteryInDays.toNumber();
		}

		function refreshRate() as Lang.Number {
			return RefreshRate.SEC;
		}
	}
} // module Data
