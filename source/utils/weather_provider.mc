// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

module WeatherProvider {
	const CACHE_TTL_HOURS as Lang.Number = 48;
	const MIN_HOURLY_FORECAST_MEMORY as Lang.Number = 131072;

	var last_refresh_hour_ as Lang.Number = -1;

	var condition_ as Lang.Number? = null;
	var temperature_ as Lang.Number? = null;
	var precipitation_chance_ as Lang.Number? = null;
	var uv_index_ as Lang.Float? = null;
	var wind_bearing_ as Lang.Number? = null;
	var wind_speed_ as Lang.Float? = null;

	function getCondition() as Lang.Number? {
		refresh_();
		return condition_;
	}

	function getTemperature() as Lang.Number? {
		refresh_();
		return temperature_;
	}

	function getPrecipitationChance() as Lang.Number? {
		refresh_();
		return precipitation_chance_;
	}

	function getUvIndex() as Lang.Float? {
		refresh_();
		return uv_index_;
	}

	function getWindBearing() as Lang.Number? {
		refresh_();
		return wind_bearing_;
	}

	function getWindSpeed() as Lang.Float? {
		refresh_();
		return wind_speed_;
	}

	function refresh_() as Void {
		var now = Time.now();
		var hour = hour_(now);
		if (self.last_refresh_hour_ == hour) {
			return;
		}

		self.clear_();

		if (self.hasHourlyForecastMemory_()) {
			if (self.refreshHourlyForecast_(hour)) {
				self.last_refresh_hour_ = hour;
				return;
			}
			if (self.loadCachedHour_(hour)) {
				self.last_refresh_hour_ = hour;
				return;
			}
		}

		if (self.refreshCurrentConditions_(hour)) {
			self.last_refresh_hour_ = hour;
		}
	}

	function clear_() as Void {
		self.condition_ = null;
		self.temperature_ = null;
		self.precipitation_chance_ = null;
		self.uv_index_ = null;
		self.wind_bearing_ = null;
		self.wind_speed_ = null;
	}

	function hasHourlyForecastMemory_() as Lang.Boolean {
		return (
			MIN_HOURLY_FORECAST_MEMORY <= System.getSystemStats().totalMemory
		);
	}

	function refreshHourlyForecast_(_hour as Lang.Number) as Lang.Boolean {
		var forecasts = Weather.getHourlyForecast();
		if (forecasts == null) {
			return false;
		}

		var selected_index = -1;
		var forecasts_size = forecasts.size();
		for (var i = 0; i < forecasts_size; ++i) {
			var forecast = forecasts[i];
			if (forecast.forecastTime == null) {
				continue;
			}

			var forecast_hour = hour_(forecast.forecastTime as Time.Moment);
			self.cacheForecast_(forecast_hour, forecast);
			if (selected_index < 0 and _hour <= forecast_hour) {
				selected_index = i;
			}
		}

		if (0 <= selected_index) {
			return self.setFromForecast_(forecasts[selected_index]);
		}

		return false;
	}

	function refreshCurrentConditions_(_hour as Lang.Number) as Lang.Boolean {
		var weather = Weather.getCurrentConditions();
		if (weather == null) {
			return false;
		}

		var any = false;

		if (weather.condition != null) {
			self.condition_ = weather.condition as Lang.Number;
			any = true;
			Cache.setValue(
				key_(_hour, "condition"),
				self.condition_ as Lang.Number
			);
		}
		if (weather.temperature != null) {
			self.temperature_ = weather.temperature as Lang.Number;
			any = true;
			Cache.setValue(
				key_(_hour, "temperature"),
				self.temperature_ as Lang.Number
			);
		}
		if (weather.precipitationChance != null) {
			self.precipitation_chance_ =
				weather.precipitationChance as Lang.Number;
			any = true;
			Cache.setValue(
				key_(_hour, "precip"),
				self.precipitation_chance_ as Lang.Number
			);
		}
		if (weather.uvIndex != null) {
			self.uv_index_ = weather.uvIndex as Lang.Float;
			any = true;
			Cache.setValue(key_(_hour, "uv"), self.uv_index_ as Lang.Float);
		}
		if (weather.windBearing != null) {
			self.wind_bearing_ = weather.windBearing as Lang.Number;
			any = true;
			Cache.setValue(
				key_(_hour, "wind_bearing"),
				self.wind_bearing_ as Lang.Number
			);
		}
		if (weather.windSpeed != null) {
			self.wind_speed_ = weather.windSpeed as Lang.Float;
			any = true;
			Cache.setValue(
				key_(_hour, "wind_speed"),
				self.wind_speed_ as Lang.Float
			);
		}

		return any;
	}

	function setFromForecast_(
		_forecast as Weather.HourlyForecast
	) as Lang.Boolean {
		var any = false;

		if (_forecast.condition != null) {
			self.condition_ = _forecast.condition as Lang.Number;
			any = true;
		}
		if (_forecast.temperature != null) {
			self.temperature_ = (
				_forecast.temperature as Lang.Numeric
			).toNumber();
			any = true;
		}
		if (_forecast.precipitationChance != null) {
			self.precipitation_chance_ =
				_forecast.precipitationChance as Lang.Number;
			any = true;
		}
		if (_forecast.uvIndex != null) {
			self.uv_index_ = _forecast.uvIndex as Lang.Float;
			any = true;
		}
		if (_forecast.windBearing != null) {
			self.wind_bearing_ = _forecast.windBearing as Lang.Number;
			any = true;
		}
		if (_forecast.windSpeed != null) {
			self.wind_speed_ = _forecast.windSpeed as Lang.Float;
			any = true;
		}

		return any;
	}

	function cacheForecast_(
		_hour as Lang.Number,
		_forecast as Weather.HourlyForecast
	) as Void {
		if (_forecast.condition != null) {
			Cache.setValue(
				key_(_hour, "condition"),
				_forecast.condition as Lang.Number
			);
		}
		if (_forecast.temperature != null) {
			Cache.setValue(
				key_(_hour, "temperature"),
				(_forecast.temperature as Lang.Numeric).toNumber()
			);
		}
		if (_forecast.precipitationChance != null) {
			Cache.setValue(
				key_(_hour, "precip"),
				_forecast.precipitationChance as Lang.Number
			);
		}
		if (_forecast.uvIndex != null) {
			Cache.setValue(key_(_hour, "uv"), _forecast.uvIndex as Lang.Float);
		}
		if (_forecast.windBearing != null) {
			Cache.setValue(
				key_(_hour, "wind_bearing"),
				_forecast.windBearing as Lang.Number
			);
		}
		if (_forecast.windSpeed != null) {
			Cache.setValue(
				key_(_hour, "wind_speed"),
				_forecast.windSpeed as Lang.Float
			);
		}
	}

	function loadCachedHour_(_hour as Lang.Number) as Lang.Boolean {
		var any = false;

		var condition = Cache.getValue(
			key_(_hour, "condition"),
			CACHE_TTL_HOURS
		);
		if (condition != null) {
			self.condition_ = condition as Lang.Number;
			any = true;
		}

		var temperature = Cache.getValue(
			key_(_hour, "temperature"),
			CACHE_TTL_HOURS
		);
		if (temperature != null) {
			self.temperature_ = temperature as Lang.Number;
			any = true;
		}

		var precip = Cache.getValue(key_(_hour, "precip"), CACHE_TTL_HOURS);
		if (precip != null) {
			self.precipitation_chance_ = precip as Lang.Number;
			any = true;
		}

		var uv = Cache.getValue(key_(_hour, "uv"), CACHE_TTL_HOURS);
		if (uv != null) {
			self.uv_index_ = uv as Lang.Float;
			any = true;
		}

		var wind_bearing = Cache.getValue(
			key_(_hour, "wind_bearing"),
			CACHE_TTL_HOURS
		);
		if (wind_bearing != null) {
			self.wind_bearing_ = wind_bearing as Lang.Number;
			any = true;
		}

		var wind_speed = Cache.getValue(
			key_(_hour, "wind_speed"),
			CACHE_TTL_HOURS
		);
		if (wind_speed != null) {
			self.wind_speed_ = wind_speed as Lang.Float;
			any = true;
		}

		return any;
	}

	function hour_(_moment as Time.Moment) as Lang.Number {
		return _moment.value() / 3600;
	}

	function key_(_hour as Lang.Number, _field as Lang.String) as Lang.String {
		return "weather_hour_" + _hour.toString() + "_" + _field;
	}
} // module WeatherProvider
