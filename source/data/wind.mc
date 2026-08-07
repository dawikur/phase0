// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class Wind extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_WIND),
				WeatherProvider.refresh_rate
			);

			self.icon = Fonts.ICON_NONE;

			WeatherProvider.register("wind_bearing");
			WeatherProvider.register("wind_speed");
		}

		function refresh() as Void {
			var wind_bearing = WeatherProvider.get("wind_bearing");
			if (wind_bearing == null) {
				self.icon = Fonts.ICON_NONE;
			} else if (wind_bearing < 0 + 22.5) {
				self.icon = Fonts.ICON_WIND_N_0;
			} else if (wind_bearing < 45 + 22.5) {
				self.icon = Fonts.ICON_WIND_NE_0;
			} else if (wind_bearing < 90 + 22.5) {
				self.icon = Fonts.ICON_WIND_E_0;
			} else if (wind_bearing < 135 + 22.5) {
				self.icon = Fonts.ICON_WIND_SE_0;
			} else if (wind_bearing < 180 + 22.5) {
				self.icon = Fonts.ICON_WIND_S_0;
			} else if (wind_bearing < 225 + 22.5) {
				self.icon = Fonts.ICON_WIND_SW_0;
			} else if (wind_bearing < 270 + 22.5) {
				self.icon = Fonts.ICON_WIND_W_0;
			} else if (wind_bearing < 315 + 22.5) {
				self.icon = Fonts.ICON_WIND_NW_0;
			} else {
				self.icon = Fonts.ICON_WIND_N_0;
			}

			var wind_speed = WeatherProvider.get("wind_speed");
			if (wind_speed == null) {
				self.value = null;
			} else {
				self.value = wind_speed.toNumber();

				if (self.icon != Fonts.ICON_NONE) {
					var icon = (self.icon as Lang.String).toCharArray()[0];
					if (self.value <= 2) {
						// pass
						// self.icon = (icon + 0).toString();
					} else if (self.value <= 6) {
						self.icon = (icon + 1).toString();
					} else {
						self.icon = (icon + 2).toString();
					}
				}
			}
		}
	}
} // module Data
