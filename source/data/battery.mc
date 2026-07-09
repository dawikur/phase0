// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

module Data {
	class Battery extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_BATTERY,
				Resources.get(Rez.Strings.LABEL_BATTERY)
			);

			self.value_max = 100;
		}

		function get_() as Lang.Number? {
			return System.getSystemStats().battery.toNumber();
		}
	}
} // module Data
