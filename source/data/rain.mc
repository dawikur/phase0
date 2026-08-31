// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Rain extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_WEATHER
					: null,
				Resources.get(Rez.Strings.LABEL_RAIN),
				WeatherProvider.refresh_rate
			);

			self.icon = Fonts.ICON_NONE;
			self.value_max = 100;

			WeatherProvider.register("precipitation_chance");
		}

		function refresh() as Void {
			self.value = WeatherProvider.get("precipitation_chance");

			if (self.value == null) {
				self.icon = Fonts.ICON_NONE;
			} else if (self.value <= 20) {
				self.icon = Fonts.ICON_RAIN_0;
			} else if (self.value <= 50) {
				self.icon = Fonts.ICON_RAIN_1;
			} else if (self.value <= 80) {
				self.icon = Fonts.ICON_RAIN_2;
			} else {
				self.icon = Fonts.ICON_RAIN_3;
			}
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
