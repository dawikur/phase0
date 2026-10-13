// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Wind extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_WEATHER
					: null,
				Resources.get(Rez.Strings.LABEL_WIND),
				WeatherProvider.refresh_rate
			);
			self.icon = windIcon(null, null);

			WeatherProvider.register("wind_bearing");
			WeatherProvider.register("wind_speed");
		}

		function defaultWidth() as Lang.Number {
			return 2;
		}

		function refresh() as Void {
			var wind_speed = WeatherProvider.get("wind_speed");
			self.value = wind_speed != null ? wind_speed.toNumber() : null;
			self.icon = windIcon(WeatherProvider.get("wind_bearing"), self.value);
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
