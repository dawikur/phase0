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

			self.icon = Fonts.ICON_NONE;

			WeatherProvider.register("high_temperature");
		}

		function refresh() as Void {
			var temperature_c = WeatherProvider.get("high_temperature");
			self.icon = temperatureIcon(temperature_c);
			self.value = temperature_c == null
				? null
				: Units.convertTemperature(temperature_c);
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
