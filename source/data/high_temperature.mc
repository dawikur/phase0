// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;

module Data {
	class HighTemperature extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_HIGH_TEMPERATURE)
			);

			WeatherProvider.register("high_temperature");
		}

		function get_() as Lang.Number? {
			return WeatherProvider.get("high_temperature");
		}
	}
} // module Data
