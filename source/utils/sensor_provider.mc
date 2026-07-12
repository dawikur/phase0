// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.SensorHistory;

module SensorProvider {
	const CACHE_TTL_HOURS as Lang.Number = 2;

	function getSensorHistoryData(
		_name as Lang.String,
		_iterator as SensorHistory.SensorHistoryIterator
	) as Lang.Number? {
		if (_iterator != null) {
			var data_maybe = _iterator.next();
			if (data_maybe != null and data_maybe.data != null) {
				var data = (data_maybe.data as Lang.Numeric).toNumber();
				Cache.setValue(key_(_name), data);
				return data;
			}
		}

		var cached = Cache.getValue(key_(_name), CACHE_TTL_HOURS);
		if (cached != null) {
			return cached as Lang.Number;
		}

		return null;
	}

	function key_(_name as Lang.String) as Lang.String {
		return "sensor_" + _name;
	}
} // module SensorProvider
