// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Weather;

module Widgets {
	class Weather extends Text {
		hidden var small_text_ as Lang.Boolean = false;

		function initialize() {
			Text.initialize(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
			self.justify_ = Render.JUSTIFY_CENTER;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.value_ = "";

			var weather = Weather.getCurrentConditions();
			if (weather != null) {
				var text = "";
				var temp = "";

				if (weather.condition != null) {
					var condition = weather.condition as Lang.Number;

					text = Resources.getCondition(condition);
				}

				if (weather.temperature != null) {
					var temperature = Data.Units.convertTemperature(
						weather.temperature as Lang.Number
					);
					var unit = Data.Units.getTemperature();

					temp = temperature.format("%d") + unit;
				}

				self.value_ = text + "  " + temp;

				if (self.value_.length() != 0) {
					if (
						Render.TextWidth(_dc, self.value_, false) <=
						self.size_x * 2
					) {
						self.small = false;
					} else {
						self.small = true;
					}
				}
			}

			if (self.value_.length() != 0) {
				Cache.setValue("weather", self.value_);
				Cache.setValue("weather_small", self.small);
			} else {
				var data = Cache.getValue("weather", 8); // 8 hours
				if (data != null) {
					self.value_ = data as Lang.String;
				}

				var data_small = Cache.getValue("weather_small", 8); // 8 hours
				if (data_small != null) {
					self.small = data_small as Lang.Boolean;
				}
			}
		}
	}
} // module Widgets
