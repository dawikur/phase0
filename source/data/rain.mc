// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Rain extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_RAIN),
				WeatherProvider.refresh_rate
			);

			self.icon = Fonts.ICON_NONE;
			self.value_max = 100;
		}

		function get_() as Lang.Number? {
			self.icon = Fonts.ICON_NONE;

			var precipitation_chance = WeatherProvider.get(
				"precipitation_chance"
			);
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
