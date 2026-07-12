// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Weather extends Text {
		hidden var small_text_ as Lang.Boolean = false;

		function initialize() {
			Text.initialize(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
			self.justify_ = Render.JUSTIFY_CENTER;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.value_ = "";

			var condition = WeatherProvider.getCondition();
			if (condition != null) {
				self.value_ = Resources.getCondition(condition);
			}

			var temperature_maybe = WeatherProvider.getTemperature();
			if (temperature_maybe != null) {
				var temperature = Data.Units.convertTemperature(
					temperature_maybe as Lang.Number
				);
				var temp =
					temperature.format("%d") + Data.Units.getTemperature();

				self.value_ += self.value_.length() == 0 ? temp : "  " + temp;
			}

			if (self.value_.length() != 0) {
				if (
					Render.TextWidth(_dc, self.value_, false) <=
					self.size_x * 2
				) {
					self.is_small = false;
				} else {
					self.is_small = true;
				}
			}
		}
	}
} // module Widgets
