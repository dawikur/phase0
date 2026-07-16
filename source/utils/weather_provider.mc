// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

module WeatherProvider {
	const CURRENT_CACHE_TTL_HOURS as Lang.Number = 4;
	const FORECAST_CACHE_MAX_HOURS as Lang.Number = 48;
	const FORECAST_CACHE_TTL_HOURS as Lang.Number = 48;
	const FORECAST_MEMORY_THRESHOLD as Lang.Number = 80 * 1024;
	const FORECAST_SNAPSHOT_KEY as Lang.String = "weather_forecast_snapshot";

	var FIELDS_ as Lang.Dictionary<Lang.String, Lang.Number?> = {};

	var last_refresh_hour as Lang.Number = -1;

	function register(_key as Lang.String) as Void {
		FIELDS_.put(_key, null);
	}

	function get(_key as Lang.String) as Lang.Number? {
		return FIELDS_.get(_key);
	}

	function refresh(_now_seconds as Lang.Number) as Void {
		var fields = FIELDS_.keys();
		if (fields.size() == 0) {
			return;
		}

		var now_hour = (_now_seconds - _now_seconds % 3600) / 3600;
		if (last_refresh_hour == now_hour) {
			return;
		}

		last_refresh_hour = now_hour;

		var should_use_forecast =
			System.getSystemStats().totalMemory > FORECAST_MEMORY_THRESHOLD;
		var weather = Weather.getCurrentConditions();
		var had_valid_forecast = should_use_forecast and hasValidForecast_();
		var stored_forecast =
			should_use_forecast and refreshForecast_(fields, now_hour);

		if (weather != null) {
			refreshCurrentConditions_(
				fields,
				weather,
				!should_use_forecast or !stored_forecast and !had_valid_forecast
			);
			return;
		}

		if (should_use_forecast) {
			refreshForecastFallback_(fields, now_hour);
			return;
		}

		refreshCurrentCache_(fields);
	}

	function refreshCurrentConditions_(
		_fields as Lang.Array<Lang.String>,
		_weather as Weather.CurrentConditions,
		_store_cache as Lang.Boolean
	) as Void {
		var fields_size = _fields.size();
		for (var i = 0; i < fields_size; ++i) {
			var key = _fields[i];

			FIELDS_.put(key, refreshCurrentValue_(
				key,
				weatherValue_(_weather, key),
				_store_cache
			));
		}
	}

	function refreshForecast_(
		_fields as Lang.Array<Lang.String>,
		_now_hour as Lang.Number
	) as Lang.Boolean {
		var forecast_maybe =
			Weather.getHourlyForecast() as Lang.Array<Weather.HourlyForecast>
				or Null;
		if (forecast_maybe == null) {
			return false;
		}

		var forecast = forecast_maybe as Lang.Array<Weather.HourlyForecast>;
		var forecast_size = forecast.size();
		if (forecast_size == 0) {
			return false;
		}

		var max_size = forecast_size;
		if (max_size > FORECAST_CACHE_MAX_HOURS) {
			max_size = FORECAST_CACHE_MAX_HOURS;
		}

		clearForecast_();
		var stored_count = 0;

		for (var i = 0; i < max_size; ++i) {
			var hourly_forecast = forecast[i] as Weather.HourlyForecast;
			var forecast_hour_maybe = forecastHour_(hourly_forecast);
			if (forecast_hour_maybe == null) {
				continue;
			}

			var forecast_hour = forecast_hour_maybe as Lang.Number;
			if (forecast_hour <= _now_hour) {
				continue;
			}
			if (forecast_hour > _now_hour + FORECAST_CACHE_MAX_HOURS) {
				continue;
			}

			stored_count += 1;

			var fields_size = _fields.size();
			for (var j = 0; j < fields_size; ++j) {
				var key = _fields[j];
				storeForecastValue_(
					key,
					forecast_hour,
					weatherValue_(hourly_forecast, key)
				);
			}
		}

		if (stored_count == 0) {
			return false;
		}

		Cache.setValue(FORECAST_SNAPSHOT_KEY, _now_hour);
		return true;
	}

	function refreshForecastFallback_(
		_fields as Lang.Array<Lang.String>,
		_now_hour as Lang.Number
	) as Void {
		if (!hasValidForecast_()) {
			refreshCurrentCache_(_fields);
			return;
		}

		var fields_size = _fields.size();
		for (var i = 0; i < fields_size; ++i) {
			var key = _fields[i];

			FIELDS_.put(key, nextForecastValue_(key, _now_hour));
		}
	}

	function refreshCurrentCache_(_fields as Lang.Array<Lang.String>) as Void {
		var fields_size = _fields.size();
		for (var i = 0; i < fields_size; ++i) {
			var key = _fields[i];

			FIELDS_.put(key, currentCacheValue_(key));
		}
	}

	function refreshCurrentValue_(
		_key as Lang.String,
		_data_maybe as Lang.Numeric?,
		_store_cache as Lang.Boolean
	) as Lang.Number? {
		if (_data_maybe != null) {
			var data = (_data_maybe as Lang.Numeric).toNumber();
			if (_store_cache) {
				Cache.setValue(_key, data);
			}
			return data;
		}

		return currentCacheValue_(_key);
	}

	function currentCacheValue_(_key as Lang.String) as Lang.Number? {
		var cached = Cache.getValue(_key, CURRENT_CACHE_TTL_HOURS);
		if (cached != null) {
			return cached as Lang.Number;
		}

		return null;
	}

	function storeForecastValue_(
		_key as Lang.String,
		_offset as Lang.Number,
		_data_maybe as Lang.Numeric?
	) as Void {
		var key = forecastKey_(_key, _offset);
		if (_data_maybe != null) {
			Cache.setValue(key, (_data_maybe as Lang.Numeric).toNumber());
			return;
		}

		Cache.clearValue(key);
	}

	function nextForecastValue_(
		_key as Lang.String,
		_now_hour as Lang.Number
	) as Lang.Number? {
		for (
			var forecast_hour = _now_hour + 1;
			forecast_hour <= _now_hour + FORECAST_CACHE_MAX_HOURS;
			++forecast_hour
		) {
			var cached = Cache.getValue(
				forecastKey_(_key, forecast_hour),
				FORECAST_CACHE_TTL_HOURS
			);
			if (cached != null) {
				return cached as Lang.Number;
			}
		}

		return currentCacheValue_(_key);
	}

	function hasValidForecast_() as Lang.Boolean {
		return Cache.hasValue(FORECAST_SNAPSHOT_KEY, FORECAST_CACHE_TTL_HOURS);
	}

	function weatherValue_(
		_weather as Weather.CurrentConditions or Weather.HourlyForecast,
		_key as Lang.String
	) as Lang.Numeric? {
		if (_key.equals("condition")) {
			return _weather.condition;
		}
		if (_key.equals("feels_like_temperature")) {
			if (_weather has :feelsLikeTemperature) {
				return _weather.feelsLikeTemperature;
			}
			return null;
		}
		if (_key.equals("high_temperature")) {
			if (_weather has :highTemperature) {
				return _weather.highTemperature;
			}
			return null;
		}
		if (_key.equals("low_temperature")) {
			if (_weather has :lowTemperature) {
				return _weather.lowTemperature;
			}
			return null;
		}
		if (_key.equals("precipitation_chance")) {
			return _weather.precipitationChance;
		}
		if (_key.equals("relative_humidity")) {
			if (_weather has :relativeHumidity) {
				return _weather.relativeHumidity;
			}
			return null;
		}
		if (_key.equals("temperature")) {
			return _weather.temperature;
		}
		if (_key.equals("uv_index")) {
			if (_weather has :uvIndex) {
				return _weather.uvIndex;
			}
			return null;
		}
		if (_key.equals("wind_bearing")) {
			return _weather.windBearing;
		}
		if (_key.equals("wind_speed")) {
			return _weather.windSpeed;
		}

		return null;
	}

	function forecastKey_(
		_key as Lang.String,
		_hour as Lang.Number
	) as Lang.String {
		return "forecast_" + _key + "_" + _hour.format("%d");
	}

	function forecastHour_(
		_forecast as Weather.HourlyForecast
	) as Lang.Number? {
		var forecast_time = _forecast.forecastTime;
		if (forecast_time == null) {
			return null;
		}

		var forecast_seconds = (forecast_time as Time.Moment).value();
		return (forecast_seconds - forecast_seconds % 3600) / 3600;
	}

	function clearForecast_() as Void {
		var snapshot = Cache.getValue(
			FORECAST_SNAPSHOT_KEY,
			FORECAST_CACHE_TTL_HOURS
		);
		if (snapshot != null) {
			var snapshot_hour = snapshot as Lang.Number;
			var fields = FIELDS_.keys();
			var fields_size = fields.size();
			for (
				var forecast_hour = snapshot_hour + 1;
				forecast_hour <= snapshot_hour + FORECAST_CACHE_MAX_HOURS;
				++forecast_hour
			) {
				for (var i = 0; i < fields_size; ++i) {
					Cache.clearValue(forecastKey_(fields[i], forecast_hour));
				}
			}
		}

		Cache.clearValue(FORECAST_SNAPSHOT_KEY);
	}
} // module WeatherProvider
