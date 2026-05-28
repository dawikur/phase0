// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Weather;

module Data {

class Rain extends Base {
	function initialize() {
		Base.initialize(
			Complications.COMPLICATION_TYPE_INVALID,
			Resources.load(Rez.Strings.LABEL_RAIN),
			CATEGORY_WEATHER
		);

		self.icon = Fonts.ICON_RAIN_0;
		self.value_max = 100;
	}

	function getMaybe_() as Lang.Number or Null {
		self.icon = Fonts.ICON_RAIN_0;

		var weather = Weather.getCurrentConditions();
		if (weather != null) {
			if (weather.precipitationChance != null) {
				var precipitation_chance = weather.precipitationChance as Lang.Number;
				if (precipitation_chance <= 20) {
					self.icon = Fonts.ICON_RAIN_0;
				} else if (precipitation_chance <= 50) {
					self.icon = Fonts.ICON_RAIN_1;
				} else if (precipitation_chance <= 80) {
					self.icon = Fonts.ICON_RAIN_2;
				} else {
					self.icon = Fonts.ICON_RAIN_3;
				}

				return precipitation_chance;
			}
		}

		return null;
	}
}

} // module Data
