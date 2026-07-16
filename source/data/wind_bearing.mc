// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

module Data {
	class WindBearing extends Base {
		function initialize() {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_INVALID
					: null,
				Resources.get(Rez.Strings.LABEL_WIND_BEARING)
			);

			self.icon = Fonts.ICON_WIND_NONE;

			WeatherProvider.register("wind_bearing");
			WeatherProvider.register("wind_speed");
		}

		function get_() as Lang.Number? {
			self.icon = Fonts.ICON_WIND_NONE;

			var wind_bearing = WeatherProvider.get("wind_bearing");
			var wind_speed = WeatherProvider.get("wind_speed");

			if (wind_bearing == null or wind_speed == null) {
				return null;
			}

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

			var icon = self.icon as Lang.String;
			if (wind_speed <= 2) {
				// pass
			} else if (wind_speed <= 6) {
				self.icon = (icon.toCharArray()[0] + 1).toString();
			} else {
				self.icon = (icon.toCharArray()[0] + 2).toString();
			}

			return wind_speed.toNumber();
		}
	}
} // module Data
