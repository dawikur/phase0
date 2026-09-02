// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.Test;

module SensorProvider {
	// Cache policy:
	// - Read the latest sensor sample every refresh to keep the displayed value
	//   current.
	// - Persist changed values immediately for offline fallback.
	// - For unchanged values, refresh only the cache timestamp once an hour.
	// - refreshValue() verifies that persistent data still exists; if it does
	//   not, write the value again instead of leaving a timestamp-only entry.

	const OPTIONS = { :period => 1 };

	const CACHE_TTL_HOURS as Lang.Number = 2;
	const CACHE_REFRESH_INTERVAL_SECONDS as Lang.Number = 60 * 60;

	var cache_values_ as Lang.Dictionary<Lang.String, Lang.Number> = {};
	var cache_refresh_seconds_ as Lang.Dictionary<Lang.String, Lang.Number> =
		{};

	function clearCache() as Void {
		cache_values_ = {};
		cache_refresh_seconds_ = {};
	}

	function getRaw(
		_iterator as SensorHistory.SensorHistoryIterator
	) as Lang.Number? {
		if (_iterator != null) {
			var data_maybe = _iterator.next();
			if (data_maybe != null and data_maybe.data != null) {
				return (data_maybe.data as Lang.Numeric).toNumber();
			}
		}

		return null;
	}

	function get(
		_name as Lang.String,
		_iterator as SensorHistory.SensorHistoryIterator
	) as Lang.Number? {
		var data_maybe = SensorProvider.getRaw(_iterator);
		if (data_maybe != null) {
			storeCacheValue_(_name, data_maybe);
			return data_maybe;
		}

		var cached = Cache.getValue(_name, CACHE_TTL_HOURS);
		if (cached != null) {
			return cached as Lang.Number;
		}

		return null;
	}

	function storeCacheValue_(
		_name as Lang.String,
		_value as Lang.Number
	) as Void {
		var now_seconds = Runtime.now.value();
		var cached_value = cache_values_.get(_name);
		var last_refresh_seconds = cache_refresh_seconds_.get(_name);

		if (cached_value == null or cached_value != _value) {
			Cache.setValue(_name, _value);
		} else if (
			last_refresh_seconds == null or
			now_seconds - last_refresh_seconds >= CACHE_REFRESH_INTERVAL_SECONDS
		) {
			if (!Cache.refreshValue(_name)) {
				Cache.setValue(_name, _value);
			}
		} else {
			return;
		}

		cache_values_.put(_name, _value);
		cache_refresh_seconds_.put(_name, now_seconds);
	}

	(:test)
	function SensorProviderCacheValueTest(
		_logger as Test.Logger
	) as Lang.Boolean {
		var key = "sensor_provider_test_value";
		Cache.clearValue(key);
		cache_values_ = {};
		cache_refresh_seconds_ = {};

		storeCacheValue_(key, 12);
		Test.assertEqual(
			Cache.getValue(key, CACHE_TTL_HOURS) as Lang.Number,
			12
		);

		Cache.clearValue(key);
		cache_refresh_seconds_.put(
			key,
			Runtime.now.value() - CACHE_REFRESH_INTERVAL_SECONDS
		);
		storeCacheValue_(key, 12);
		Test.assertEqual(
			Cache.getValue(key, CACHE_TTL_HOURS) as Lang.Number,
			12
		);

		Cache.clearValue(key);
		cache_values_ = {};
		cache_refresh_seconds_ = {};
		return true;
	}
} // module SensorProvider
