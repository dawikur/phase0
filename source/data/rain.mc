// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

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

			self.icon = rainIcon(null);
			self.value_max = 100;

			WeatherProvider.register("precipitation_chance");
		}

		function defaultWidth() as Lang.Number {
			return 2;
		}

		function refresh() as Void {
			self.value = WeatherProvider.get("precipitation_chance");

			self.icon = rainIcon(self.value);
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
