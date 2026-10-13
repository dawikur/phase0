// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;

module Data {
	class RelativeHumidity extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_WEATHER
					: null,
				Resources.get(Rez.Strings.LABEL_RELATIVE_HUMIDITY),
				WeatherProvider.refresh_rate
			);
			self.value_max = 100;
			self.icon = humidityIcon(null);

			WeatherProvider.register("relative_humidity");
		}

		function refresh() as Void {
			self.value = WeatherProvider.get("relative_humidity");
			self.icon = humidityIcon(self.value);
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
