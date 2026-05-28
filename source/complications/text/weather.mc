// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Weather;

module Complication {

class Weather extends Text {
	hidden var original_small_ as Lang.Boolean = false;

	function initialize(_small as Lang.Boolean) {
		Text.initialize(Complications.COMPLICATION_TYPE_CURRENT_WEATHER, _small);
		self.original_small_ = _small;

		self.justify_ = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.value_ = "";

		var weather = Weather.getCurrentConditions();
		if (weather != null) {
			var text = "";
			var temp = "";

			if (weather.condition != null) {
				var condition = weather.condition as Lang.Number;

				text = Resources.loadCondition(condition);
			}

			if (weather.temperature != null) {
				var temperature = Data.Units.convertTemperature(weather.temperature as Lang.Number);
				var unit = Data.Units.getTemperature();

				temp = temperature.format("%d") + unit;
			}

			self.value_ = text + "  " + temp;

			if (self.value_.length() != 0) {
				if (!self.original_small_) {
					if (Render.textWidth(_dc, self.value_, false) <= self.size_x) {
						self.small_ = false;
					} else {
						self.small_ = true;
					}
				} else {
					self.small_ = true;
				}
			}

			// TODO: loadConditionShort
			// if (Render.textWidth(_dc, self.value_, self.small_) <= self.size_x) {
			// } else {
			// }
		}

		if (self.value_.length() != 0) {
			Cache.setValue("weather", self.value_);
			Cache.setValue("weather_small", self.small_);
		} else {
			var data = Cache.getValue("weather", 8); // 8 hours
			if (data != null) {
				self.value_ = data as Lang.String;
			}

			var data_small = Cache.getValue("weather_small", 8); // 8 hours
			if (data_small != null) {
				self.small_ = data_small as Lang.Boolean;
			}
		}
	}
}

} // module Complication
