// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

module Data {
	class BatteryPercentage extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_BATTERY
					: null,
				Resources.get(Rez.Strings.LABEL_BATTERY_PERCENTAGE),
				RefreshRate.SEC
			);

			self.value_max = 100;
		}

		function refresh() as Void {
			self.value = System.getSystemStats().battery.toNumber();
		}
	}
} // module Data
