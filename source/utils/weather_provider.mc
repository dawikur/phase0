// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Time;
import Toybox.Weather;

module WeatherProvider {
	typedef ForecastSnapshot as Lang.Dictionary<
		Application.Storage.KeyType,
		Application.Storage.ValueType
	>;

	// Refresh policy:
	// - Request current conditions immediately after fields are registered.
	// - Retry them every minute while any registered field is missing from the
	//   current snapshot. This makes weather appear promptly after phone sync.
	// - Return to a steady hourly cadence once the current snapshot is complete.
	// - Cached values may be rendered during recovery, but do not make a current
	//   snapshot complete: stale data must not suppress the fast retry.
	// - During fast retry, unchanged current values refresh only their cache
	//   timestamp at most once an hour; changed values are stored immediately.
	// - Forecast refresh and its persistent-cache rewrite remain hourly, even
	//   during fast current-condition retries, to limit storage and battery use.

	const CURRENT_CACHE_TTL_HOURS as Lang.Number = 4;
	const FORECAST_CACHE_TTL_HOURS as Lang.Number = 12;
	const FORECAST_MEMORY_THRESHOLD as Lang.Number = 100 * 1024;
	const FORECAST_SNAPSHOT_KEY as Lang.String = "weather_forecast_snapshot";
	const FORECAST_SNAPSHOT_HOUR_KEY as Lang.String = "snapshot_hour";
	const RETRY_INTERVAL_SECONDS as Lang.Number = 60;
	const CURRENT_CACHE_REFRESH_INTERVAL_SECONDS as Lang.Number = 60 * 60;
	const SHOULD_USE_FORECAST =
		System.getSystemStats().totalMemory > FORECAST_MEMORY_THRESHOLD;

	var fields_ as Lang.Dictionary<Lang.String, Lang.Number?> = {};
	var current_cache_values_ as Lang.Dictionary<Lang.String, Lang.Number> =
		{};
	var current_cache_refresh_seconds_ as Lang.Dictionary<
		Lang.String,
		Lang.Number
	> = {};
	var last_forecast_refresh_hour_ as Lang.Number = -1;
	var next_refresh_seconds_ as Lang.Number = 0;

	const refresh_rate as Lang.Number = RefreshRate.HOUR;

	function register(_key as Lang.String) as Void {
		if (!fields_.hasKey(_key)) {
			fields_.put(_key, null);
			last_forecast_refresh_hour_ = -1;
			next_refresh_seconds_ = 0;
		}
	}

	function clearCache() as Void {
		fields_ = {};
		current_cache_values_ = {};
		current_cache_refresh_seconds_ = {};
		last_forecast_refresh_hour_ = -1;
		next_refresh_seconds_ = 0;
	}

	function get(_key as Lang.String) as Lang.Number? {
		return fields_.get(_key);
	}

	function refresh() as Void {
		var now_seconds = Runtime.now.value();
		if (now_seconds < next_refresh_seconds_) {
			return;
		}

		var fields = fields_.keys();
		if (fields.size() == 0) {
			return;
		}

		var now_hour = (now_seconds - (now_seconds % 3600)) / 3600;
		var weather = Weather.getCurrentConditions();
		var had_valid_forecast = SHOULD_USE_FORECAST and hasValidForecast_();
		var stored_forecast = false;
		if (
			SHOULD_USE_FORECAST and
			last_forecast_refresh_hour_ != now_hour
		) {
			stored_forecast = refreshForecast_(fields, now_hour);
			last_forecast_refresh_hour_ = now_hour;
		}
		var has_missing_current_fields = true;

		if (weather != null) {
			has_missing_current_fields = refreshCurrentConditions_(
				fields,
				weather,
				!SHOULD_USE_FORECAST or
					(!stored_forecast and !had_valid_forecast)
			);
		} else if (SHOULD_USE_FORECAST and stored_forecast) {
			refreshForecastFallback_(fields, now_hour);
		} else if (SHOULD_USE_FORECAST) {
			refreshForecastFallback_(fields, now_hour);
		} else {
			refreshCurrentCache_(fields);
		}

		next_refresh_seconds_ = nextRefreshSeconds_(
			now_seconds,
			now_hour,
			has_missing_current_fields
		);
	}

	function nextRefreshSeconds_(
		_now_seconds as Lang.Number,
		_now_hour as Lang.Number,
		_has_missing_current_fields as Lang.Boolean
	) as Lang.Number {
		if (_has_missing_current_fields) {
			return _now_seconds + RETRY_INTERVAL_SECONDS;
		}

		return (_now_hour + 1) * 3600;
	}

	function refreshCurrentConditions_(
		_fields as Lang.Array<Lang.String>,
		_weather as Weather.CurrentConditions,
		_store_cache as Lang.Boolean
	) as Lang.Boolean {
		var has_missing_current_fields = false;
		var fields_size = _fields.size();
		for (var i = 0; i < fields_size; ++i) {
			var key = _fields[i];
			var weather_value = weatherValue_(_weather, key);
			if (weather_value == null) {
				has_missing_current_fields = true;
			}

			fields_.put(
				key,
				refreshCurrentValue_(
					key,
					weather_value,
					_store_cache
				)
			);
		}

		return has_missing_current_fields;
	}

	function refreshForecast_(
		_fields as Lang.Array<Lang.String>,
		_now_hour as Lang.Number
	) as Lang.Boolean {
		var forecast_maybe =
			Weather.getHourlyForecast() as Lang.Array<Weather.HourlyForecast>?;
		if (forecast_maybe == null) {
			return false;
		}

		var forecast = forecast_maybe as Lang.Array<Weather.HourlyForecast>;
		var forecast_size = forecast.size();
		if (forecast_size == 0) {
			return false;
		}

		var max_size = forecast_size;
		if (max_size > FORECAST_CACHE_TTL_HOURS) {
			max_size = FORECAST_CACHE_TTL_HOURS;
		}

		var snapshot = newForecastSnapshot_(_now_hour);
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
			if (forecast_hour > _now_hour + FORECAST_CACHE_TTL_HOURS) {
				continue;
			}

			stored_count += 1;

			var fields_size = _fields.size();
			for (var j = 0; j < fields_size; ++j) {
				var key = _fields[j];
				storeForecastSnapshotValue_(
					snapshot,
					key,
					forecast_hour,
					weatherValue_(hourly_forecast, key)
				);
			}
		}

		if (stored_count == 0) {
			return false;
		}

		storeForecastSnapshot_(snapshot);
		return true;
	}

	function refreshForecastFallback_(
		_fields as Lang.Array<Lang.String>,
		_now_hour as Lang.Number
	) as Void {
		var snapshot = loadForecastSnapshot_();
		if (
			snapshot == null or
			!isValidForecastSnapshot_(
				snapshot as ForecastSnapshot,
				_now_hour
			)
		) {
			refreshCurrentCache_(_fields);
			return;
		}

		var fields_size = _fields.size();
		for (var i = 0; i < fields_size; ++i) {
			var key = _fields[i];

			fields_.put(
				key,
				nextForecastValue_(
					snapshot as ForecastSnapshot,
					key,
					_now_hour
				)
			);
		}
	}

	function refreshCurrentCache_(_fields as Lang.Array<Lang.String>) as Void {
		var fields_size = _fields.size();
		for (var i = 0; i < fields_size; ++i) {
			var key = _fields[i];

			fields_.put(key, currentCacheValue_(key));
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
				storeCurrentCacheValue_(_key, data);
			}
			return data;
		}

		return currentCacheValue_(_key);
	}

	function storeCurrentCacheValue_(
		_key as Lang.String,
		_value as Lang.Number
	) as Void {
		var now_seconds = Runtime.now.value();
		var cached_value = current_cache_values_.get(_key);
		var last_refresh_seconds = current_cache_refresh_seconds_.get(_key);

		if (cached_value == null or cached_value != _value) {
			Cache.setValue(_key, _value);
		} else if (
			last_refresh_seconds == null or
			now_seconds - last_refresh_seconds >=
				CURRENT_CACHE_REFRESH_INTERVAL_SECONDS
		) {
			if (!Cache.refreshValue(_key)) {
				Cache.setValue(_key, _value);
			}
		} else {
			return;
		}

		current_cache_values_.put(_key, _value);
		current_cache_refresh_seconds_.put(_key, now_seconds);
	}

	function currentCacheValue_(_key as Lang.String) as Lang.Number? {
		var cached = Cache.getValue(_key, CURRENT_CACHE_TTL_HOURS);
		if (cached != null) {
			return cached as Lang.Number;
		}

		return null;
	}

	function newForecastSnapshot_(
		_now_hour as Lang.Number
	) as ForecastSnapshot {
		var snapshot = {} as ForecastSnapshot;
		snapshot.put(FORECAST_SNAPSHOT_HOUR_KEY, _now_hour);
		return snapshot;
	}

	function storeForecastSnapshotValue_(
		_snapshot as ForecastSnapshot,
		_key as Lang.String,
		_offset as Lang.Number,
		_data_maybe as Lang.Numeric?
	) as Void {
		if (_data_maybe != null) {
			_snapshot.put(
				forecastKey_(_key, _offset),
				(_data_maybe as Lang.Numeric).toNumber()
			);
		}
	}

	function storeForecastSnapshot_(
		_snapshot as ForecastSnapshot
	) as Void {
		Application.Storage.setValue(FORECAST_SNAPSHOT_KEY, _snapshot);
	}

	function nextForecastValue_(
		_snapshot as ForecastSnapshot,
		_key as Lang.String,
		_now_hour as Lang.Number
	) as Lang.Number? {
		for (
			var forecast_hour = _now_hour + 1;
			forecast_hour <= _now_hour + FORECAST_CACHE_TTL_HOURS;
			++forecast_hour
		) {
			var value = snapshotValue_(
				_snapshot,
				forecastKey_(_key, forecast_hour)
			);
			if (value != null) {
				return value;
			}
		}

		return null;
	}

	function hasValidForecast_() as Lang.Boolean {
		var snapshot = loadForecastSnapshot_();
		if (snapshot == null) {
			return false;
		}

		var now_seconds = Runtime.now.value();
		var now_hour = (now_seconds - (now_seconds % 3600)) / 3600;
		return isValidForecastSnapshot_(
			snapshot as ForecastSnapshot,
			now_hour
		);
	}

	function isValidForecastSnapshot_(
		_snapshot as ForecastSnapshot,
		_now_hour as Lang.Number
	) as Lang.Boolean {
		var snapshot_hour = snapshotValue_(
			_snapshot,
			FORECAST_SNAPSHOT_HOUR_KEY
		);
		if (snapshot_hour == null) {
			return false;
		}

		return (
			snapshot_hour <= _now_hour and
			_now_hour < snapshot_hour + FORECAST_CACHE_TTL_HOURS
		);
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
		return (forecast_seconds - (forecast_seconds % 3600)) / 3600;
	}

	function clearForecast_() as Void {
		Application.Storage.deleteValue(FORECAST_SNAPSHOT_KEY);
	}

	function loadForecastSnapshot_() as ForecastSnapshot? {
		var stored_snapshot = Application.Storage.getValue(
			FORECAST_SNAPSHOT_KEY
		);
		if (stored_snapshot == null) {
			return null;
		}

		try {
			var snapshot = stored_snapshot as ForecastSnapshot;
			if (snapshotValue_(snapshot, FORECAST_SNAPSHOT_HOUR_KEY) == null) {
				return null;
			}

			return snapshot;
		} catch (ex instanceof Lang.UnexpectedTypeException) {
			return null;
		}
	}

	function snapshotValue_(
		_snapshot as ForecastSnapshot,
		_key as Lang.String
	) as Lang.Number? {
		var value = _snapshot.get(_key);
		if (value == null) {
			return null;
		}

		try {
			return value as Lang.Number;
		} catch (ex instanceof Lang.UnexpectedTypeException) {
			return null;
		}
	}

	function clearWeatherProviderTestState_() as Void {
		Cache.clearValue("weather_provider_test_condition");
		Cache.clearValue("weather_provider_test_temperature");
		clearForecast_();
		fields_ = {};
		current_cache_values_ = {};
		current_cache_refresh_seconds_ = {};
		last_forecast_refresh_hour_ = -1;
		next_refresh_seconds_ = 0;
	}

	function assertNull_(_value as Lang.Object?) as Void {
		Test.assertEqual(_value == null, true);
	}

	function assertNumberEqual_(
		_actual as Lang.Number?,
		_expected as Lang.Number?
	) as Void {
		if (_expected == null) {
			assertNull_(_actual);
			return;
		}

		Test.assertEqual(_actual != null, true);
		Test.assertEqual(_actual as Lang.Number, _expected as Lang.Number);
	}

	function assertCacheValueEqual_(
		_key as Lang.String,
		_ttl_in_hours as Lang.Number,
		_expected as Lang.Number?
	) as Void {
		var cached = Cache.getValue(_key, _ttl_in_hours);
		if (_expected == null) {
			assertNull_(cached);
			return;
		}

		Test.assertEqual(cached != null, true);
		Test.assertEqual(cached as Lang.Number, _expected as Lang.Number);
	}

	function assertForecastValue_(
		_key as Lang.String,
		_hour as Lang.Number,
		_expected as Lang.Number?
	) as Void {
		var snapshot = loadForecastSnapshot_();
		if (_expected == null) {
			if (snapshot == null) {
				return;
			}
			assertNull_(snapshotValue_(snapshot as ForecastSnapshot, forecastKey_(_key, _hour)));
			return;
		}

		Test.assertEqual(snapshot != null, true);
		assertNumberEqual_(
			snapshotValue_(snapshot as ForecastSnapshot, forecastKey_(_key, _hour)),
			_expected
		);
	}

	(:test)
	function WeatherProviderCurrentCacheTest(
		_logger as Test.Logger
	) as Lang.Boolean {
		clearWeatherProviderTestState_();

		var field = "weather_provider_test_temperature";
		last_forecast_refresh_hour_ = 42;
		next_refresh_seconds_ = 42;
		register(field);
		Test.assertEqual(last_forecast_refresh_hour_, -1);
		Test.assertEqual(next_refresh_seconds_, 0);

		Test.assertEqual(forecastKey_(field, 42), "forecast_" + field + "_42");

		assertNumberEqual_(refreshCurrentValue_(field, null, false), null);

		Cache.setValue(field, 12);
		assertNumberEqual_(refreshCurrentValue_(field, null, false), 12);

		assertNumberEqual_(refreshCurrentValue_(field, 27.8, false), 27);
		assertCacheValueEqual_(field, CURRENT_CACHE_TTL_HOURS, 12);

		assertNumberEqual_(refreshCurrentValue_(field, 33, true), 33);
		assertCacheValueEqual_(field, CURRENT_CACHE_TTL_HOURS, 33);

		Application.Storage.setValue(field + "_timestamp", 1);
		assertNumberEqual_(refreshCurrentValue_(field, 33, true), 33);
		Test.assertEqual(
			Application.Storage.getValue(field + "_timestamp") as Lang.Number,
			1
		);

		assertNumberEqual_(refreshCurrentValue_(field, 34, true), 34);
		assertCacheValueEqual_(field, CURRENT_CACHE_TTL_HOURS, 34);

		Cache.clearValue(field);
		current_cache_refresh_seconds_.put(
			field,
			Runtime.now.value() - CURRENT_CACHE_REFRESH_INTERVAL_SECONDS
		);
		assertNumberEqual_(refreshCurrentValue_(field, 34, true), 34);
		assertCacheValueEqual_(field, CURRENT_CACHE_TTL_HOURS, 34);

		clearWeatherProviderTestState_();
		return true;
	}

	(:test)
	function WeatherProviderRefreshScheduleTest(
		_logger as Test.Logger
	) as Lang.Boolean {
		Test.assertEqual(nextRefreshSeconds_(750, 0, true), 810);
		Test.assertEqual(nextRefreshSeconds_(750, 0, false), 3600);
		Test.assertEqual(nextRefreshSeconds_(43830, 12, false), 46800);

		return true;
	}

	(:test)
	function WeatherProviderForecastCacheTest(
		_logger as Test.Logger
	) as Lang.Boolean {
		clearWeatherProviderTestState_();

		var condition = "weather_provider_test_condition";
		var temperature = "weather_provider_test_temperature";
		var now_seconds = Runtime.now.value();
		var now_hour = (now_seconds - (now_seconds % 3600)) / 3600;

		get(condition);
		get(temperature);

		var snapshot = newForecastSnapshot_(now_hour);
		storeForecastSnapshotValue_(snapshot, condition, now_hour + 1, 7);
		storeForecastSnapshotValue_(snapshot, condition, now_hour + 3, 9);
		storeForecastSnapshotValue_(snapshot, temperature, now_hour + 2, 21);
		storeForecastSnapshot_(snapshot);

		assertNumberEqual_(nextForecastValue_(snapshot, condition, now_hour), 7);
		assertNumberEqual_(nextForecastValue_(snapshot, temperature, now_hour), 21);
		assertNumberEqual_(
			nextForecastValue_(snapshot, temperature, now_hour + 2),
			null
		);

		refreshForecastFallback_([condition, temperature], now_hour);
		assertNumberEqual_(get(condition), 7);
		assertNumberEqual_(get(temperature), 21);

		assertForecastValue_(temperature, now_hour + 1, null);

		clearWeatherProviderTestState_();
		return true;
	}

	(:test)
	function WeatherProviderForecastCleanupTest(
		_logger as Test.Logger
	) as Lang.Boolean {
		clearWeatherProviderTestState_();

		var condition = "weather_provider_test_condition";
		var temperature = "weather_provider_test_temperature";
		var now_seconds = Runtime.now.value();
		var snapshot_hour =
			(now_seconds - (now_seconds % 3600)) / 3600;

		get(condition);
		get(temperature);

		var snapshot = newForecastSnapshot_(snapshot_hour);
		storeForecastSnapshotValue_(snapshot, condition, snapshot_hour + 1, 1);
		storeForecastSnapshotValue_(snapshot, condition, snapshot_hour + 2, 2);
		storeForecastSnapshotValue_(snapshot, temperature, snapshot_hour + 1, 3);
		storeForecastSnapshot_(snapshot);

		clearForecast_();

		Test.assertEqual(loadForecastSnapshot_() == null, true);
		assertForecastValue_(condition, snapshot_hour + 1, null);
		assertForecastValue_(condition, snapshot_hour + 2, null);
		assertForecastValue_(temperature, snapshot_hour + 1, null);

		Cache.setValue(condition, 44);
		refreshForecastFallback_([condition], snapshot_hour);
		assertNumberEqual_(get(condition), 44);

		clearWeatherProviderTestState_();
		return true;
	}
} // get("module") WeatherProvider
