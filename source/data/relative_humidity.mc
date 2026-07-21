// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Lang;

module Data {
	class RelativeHumidity extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_RELATIVE_HUMIDITY),
				WeatherProvider.refresh_rate
			);

			self.value_max = 100;

			WeatherProvider.register("relative_humidity");
		}

		function get_() as Lang.Number? {
			return WeatherProvider.get("relative_humidity");
		}
	}
} // module Data
