// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Rain extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_INVALID,
				Resources.get(Rez.Strings.LABEL_RAIN)
			);

			self.icon = Fonts.ICON_RAIN_0;
			self.value_max = 100;
		}

		function get_() as Lang.Number? {
			self.icon = Fonts.ICON_RAIN_0;

			var precipitation_chance = WeatherProvider.getPrecipitationChance();
			if (precipitation_chance != null) {
				if (precipitation_chance <= 20) {
					self.icon = Fonts.ICON_RAIN_0;
				} else if (precipitation_chance <= 50) {
					self.icon = Fonts.ICON_RAIN_1;
				} else if (precipitation_chance <= 80) {
					self.icon = Fonts.ICON_RAIN_2;
				} else {
					self.icon = Fonts.ICON_RAIN_3;
				}

				return precipitation_chance;
			}

			return null;
		}
	}
} // module Data
