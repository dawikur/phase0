// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

module Widgets {
	class Weather extends Text {
		function initialize() {
			Text.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_CURRENT_WEATHER
					: null,
				WeatherProvider.refresh_rate
			);

			self.justify_ = Render.JUSTIFY_CENTER;

			WeatherProvider.register("condition");
			WeatherProvider.register("temperature");
		}

		function weatherValue_(
			_condition as Lang.Number?,
			_use_short as Lang.Boolean,
			_temp as Lang.String
		) as Lang.String {
			var value = "";

			if (_condition != null) {
				var condition = _condition as Lang.Number;
				value = _use_short
					? Resources.getConditionShort(condition)
					: Resources.getCondition(condition);
			}

			if (_temp.length() != 0) {
				value += value.length() == 0 ? _temp : "  " + _temp;
			}

			return value;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var condition = WeatherProvider.get("condition");
			var temp = "";

			var temperature_maybe = WeatherProvider.get("temperature");
			if (temperature_maybe != null) {
				var temperature = Data.Units.convertTemperature(
					temperature_maybe as Lang.Number
				);
				temp = temperature.format("%d") + Data.Units.getTemperature();
			}

			if (
				self.tryApplyWeatherCandidate_(
					_dc,
					condition,
					temp,
					false,
					Render.SIZE_REGULAR
				) or
				self.tryApplyWeatherCandidate_(
					_dc,
					condition,
					temp,
					false,
					Render.SIZE_SMALL
				) or
				self.tryApplyWeatherCandidate_(
					_dc,
					condition,
					temp,
					true,
					Render.SIZE_REGULAR
				) or
				self.tryApplyWeatherCandidate_(
					_dc,
					condition,
					temp,
					true,
					Render.SIZE_SMALL
				)
			) {
			}
		}

		hidden function tryApplyWeatherCandidate_(
			_dc as Graphics.Dc,
			_condition as Lang.Number?,
			_temp as Lang.String,
			_use_short as Lang.Boolean,
			_is_small as Lang.Boolean
		) as Lang.Boolean {
			self.value_ = self.weatherValue_(_condition, _use_short, _temp);
			return self.tryApplyCandidate_(
				_dc,
				_is_small,
				false,
				self.size_x,
				self.size_y
			);
		}
	}
} // module Widgets
