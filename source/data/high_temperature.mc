// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Complications;
import Toybox.Lang;

module Data {
	class HighTemperature extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_WEATHER
					: null,
				Resources.get(Rez.Strings.LABEL_HIGH_TEMPERATURE),
				WeatherProvider.refresh_rate
			);

			WeatherProvider.register("high_temperature");
		}

		function refresh() as Void {
			self.value = WeatherProvider.get("high_temperature");
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
