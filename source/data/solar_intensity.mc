// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Data {
	class SolarIntensity extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_SOLAR_INPUT
					: null,
				Resources.get(Rez.Strings.LABEL_SOLAR_INTENSITY),
				RefreshRate.MIN
			);

			self.value_max = 100;
		}

		function refresh() as Void {
			var value = System.getSystemStats().solarIntensity;
			self.value = value != null and 0 <= value ? value : null;
		}
	}
} // module Data
