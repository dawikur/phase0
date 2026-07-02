// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Weather;

module Data {
	class Wind extends Base {
		function initialize() {
			Base.initialize(
				Complications.COMPLICATION_TYPE_INVALID,
				Resources.get(Rez.Strings.LABEL_WIND),
				CATEGORY_WEATHER
			);

			self.icon = Fonts.ICON_WIND_NONE;
		}

		function getMaybe_() as Lang.Number? {
			self.icon = Fonts.ICON_WIND_NONE;

			var weather = Weather.getCurrentConditions();
			if (weather != null) {
				if (weather.windBearing != null) {
					var wind_bearing = weather.windBearing as Lang.Number;
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

					if (weather.windSpeed != null) {
						var wind_speed = weather.windSpeed as Lang.Float;
						if (wind_speed <= 2) {
							// pass
						} else if (wind_speed <= 6) {
							self.icon = (
								self.icon.toCharArray()[0] + 1
							).toString();
						} else {
							self.icon = (
								self.icon.toCharArray()[0] + 2
							).toString();
						}

						return wind_speed.toNumber();
					}
				}
			}

			return null;
		}
	}
} // module Data
