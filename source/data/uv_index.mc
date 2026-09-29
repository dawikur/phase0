// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class UvIndex extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_WEATHER
					: null,
				Resources.get(Rez.Strings.LABEL_UV_INDEX),
				WeatherProvider.refresh_rate
			);
			self.icon = Fonts.ICON_NONE;

			WeatherProvider.register("uv_index");
		}

		function defaultWidth() as Lang.Number {
			return 2;
		}

		function refresh() as Void {
			var uv_index = WeatherProvider.get("uv_index");
			if (uv_index == null) {
				self.value = null;
				self.icon = Fonts.ICON_NONE;
			} else {
				self.value = uv_index.toNumber();

				if (self.value < 2) {
					self.icon = Fonts.ICON_UV_LOW;
				} else if (self.value < 5) {
					self.icon = Fonts.ICON_UV_MODERATE;
				} else if (self.value < 7) {
					self.icon = Fonts.ICON_UV_HIGH;
				} else if (self.value < 9) {
					self.icon = Fonts.ICON_UV_VERY_HIGH;
				} else {
					self.icon = Fonts.ICON_UV_EXTREME;
				}
			}
		}

		function refreshRevision() as Lang.Number? {
			return WeatherProvider.revision;
		}
	}
} // module Data
