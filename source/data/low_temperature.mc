// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;

module Data {
	class LowTemperature extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_LOW_TEMPERATURE)
			);

			WeatherProvider.register("low_temperature");
		}

		function get_() as Lang.Number? {
			return WeatherProvider.get("low_temperature");
		}
	}
} // module Data
