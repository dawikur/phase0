// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	(:data_icon)
	class UvIndex extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_WEATHER
					: null,
				Resources.get(Rez.Strings.LABEL_UV_INDEX),
				WeatherProvider.refresh_rate
			);
			self.icon = uvIcon(null);

			WeatherProvider.register("uv_index");
		}

		function defaultWidth() as Lang.Number {
			return 2;
		}

		function refresh() as Void {
			var uv_index = WeatherProvider.get("uv_index");
			self.value = uv_index != null ? uv_index.toNumber() : null;
			self.icon = uvIcon(self.value);
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
