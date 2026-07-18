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
		}

		function get_() as Lang.Number? {
			self.icon = Fonts.ICON_NONE;

			var wind_bearing = WeatherProvider.get("wind_bearing");
			if (wind_bearing != null) {
				if (wind_bearing < 0 + 22.5) {
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
			}

			var wind_speed = WeatherProvider.get("wind_speed");
			if (wind_speed != null) {
				if (self.icon != Fonts.ICON_NONE) {
					var icon = self.icon as Lang.String;
					if (wind_speed <= 2) {
						// pass
					} else if (wind_speed <= 6) {
						self.icon = (icon.toCharArray()[0] + 1).toString();
					} else {
						self.icon = (icon.toCharArray()[0] + 2).toString();
					}
				}

				return wind_speed.toNumber();
			}

			return null;
		}
	}
} // module Data
