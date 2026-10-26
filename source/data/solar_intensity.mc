// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.UserProfile;

module Data {
	(:data_gauge,:data_icon)
	class SolarIntensity extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_SOLAR_INPUT
					: null,
				Resources.get(Rez.Strings.LABEL_SOLAR_INTENSITY),
				Data.RefreshRate.MIN
			);

			self.value_max = 100;
			self.icon = solarIntensityIcon(null);
		}

		function refresh() as Void {
			var value = System.getSystemStats().solarIntensity;
			self.value = value != null and 0 <= value ? value : null;
			self.icon = solarIntensityIcon(self.value);
		}
	}
} // module Data
