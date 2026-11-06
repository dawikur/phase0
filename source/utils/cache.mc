// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

module Cache {
	typedef Data as Lang.String or Lang.Number or Lang.Float or Lang.Boolean;

	function setValue(_name as Lang.String, _data as Data) as Void {
		var now = Runtime.now.value();

		Application.Storage.setValue(_name, _data);
		Application.Storage.setValue(_name + "_timestamp", now);
	}

	function refreshValue(_name as Lang.String) as Lang.Boolean {
		if (Application.Storage.getValue(_name) == null) {
			return false;
		}

		Application.Storage.setValue(_name + "_timestamp", Runtime.now.value());
		return true;
	}

	function hasValue(
		_name as Lang.String,
		_ttl_in_hours as Lang.Number
	) as Lang.Boolean {
		return getValue(_name, _ttl_in_hours) != null;
	}

	function getValue(
		_name as Lang.String,
		_ttl_in_hours as Lang.Number
	) as Data? {
		var data_maybe = Application.Storage.getValue(_name);
		var timestamp_maybe = Application.Storage.getValue(
			_name + "_timestamp"
		);

		if (data_maybe == null and timestamp_maybe == null) {
			return null;
		}

		if (data_maybe == null or timestamp_maybe == null) {
			clearValue(_name);
			return null;
		}

		try {
			var data = data_maybe as Data;
			var timestamp = timestamp_maybe as Lang.Number;

			var data_age = Runtime.now.value() - timestamp;

			if (0 <= data_age and data_age < _ttl_in_hours * 3600) {
				return data;
			}
		} catch (ex instanceof Lang.UnexpectedTypeException) {}

		clearValue(_name);

		return null;
	}

	function clearValue(_name as Lang.String) as Void {
		Application.Storage.deleteValue(_name);
		Application.Storage.deleteValue(_name + "_timestamp");
	}

	function clearTestValue_(_name as Lang.String) as Void {
		Application.Storage.deleteValue(_name);
		Application.Storage.deleteValue(_name + "_timestamp");
	}

	(:test)
	function CacheRoundTripTest(_logger as Test.Logger) as Lang.Boolean {
		var value;
		var key = "cache_test_round_trip";
		clearTestValue_(key);

		setValue(key, 123);
		Test.assert(hasValue(key, 1));
		value = getValue(key, 1);
		Test.assert(value != null);
		Test.assertEqual(value as Lang.Number, 123);

		clearValue(key);
		Test.assert(!hasValue(key, 1));
		value = getValue(key, 1);
		Test.assert(value == null);

		return true;
	}

	(:test)
	function CacheExpiryAndCleanupTest(_logger as Test.Logger) as Lang.Boolean {
		var key = "cache_test_expiry";
		clearTestValue_(key);

		setValue(key, 55);
		Test.assert(!hasValue(key, 0));
		Test.assert(getValue(key, 1) == null);

		Application.Storage.setValue(key, 77);
		Application.Storage.setValue(key + "_timestamp", "bad");
		Test.assert(getValue(key, 1) == null);
		Test.assert(Application.Storage.getValue(key) == null);
		Test.assert(Application.Storage.getValue(key + "_timestamp") == null);

		Application.Storage.setValue(key, 88);
		Test.assert(getValue(key, 1) == null);
		Test.assert(Application.Storage.getValue(key) == null);
		Test.assert(Application.Storage.getValue(key + "_timestamp") == null);

		return true;
	}

	(:test)
	function CacheRefreshValueTest(_logger as Test.Logger) as Lang.Boolean {
		var key = "cache_test_refresh";
		clearTestValue_(key);

		Application.Storage.setValue(key, 123);
		Application.Storage.setValue(key + "_timestamp", 1);
		Test.assert(refreshValue(key));

		Test.assertEqual(Application.Storage.getValue(key) as Lang.Number, 123);
		Test.assert(
			1 <
				(
					Application.Storage.getValue(key + "_timestamp") as
						Lang.Number
				)
		);

		clearTestValue_(key);
		Test.assert(!refreshValue(key));
		return true;
	}
} // module Cache
