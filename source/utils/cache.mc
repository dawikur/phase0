// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

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

	function clearTestValue_(_name as Lang.String) as Void {
		Application.Storage.deleteValue(_name);
		Application.Storage.deleteValue(_name + "_timestamp");
	}

	(:test)
	function CacheRoundTripTest(_logger as Test.Logger) as Lang.Boolean {
		var key = "cache_test_round_trip";
		clearTestValue_(key);

		setValue(key, 123);
		Test.assertEqual(hasValue(key, 1), true);
		assertNumberEqual_(getValue(key, 1) as Lang.Number?, 123);

		clearValue(key);
		Test.assertEqual(hasValue(key, 1), false);
		assertNull_(getValue(key, 1));

		return true;
	}

	(:test)
	function CacheExpiryAndCleanupTest(_logger as Test.Logger) as Lang.Boolean {
		var key = "cache_test_expiry";
		clearTestValue_(key);

		setValue(key, 55);
		Test.assertEqual(hasValue(key, 0), false);
		assertNull_(getValue(key, 1));

		Application.Storage.setValue(key, 77);
		Application.Storage.setValue(key + "_timestamp", "bad");
		assertNull_(getValue(key, 1));
		assertNull_(Application.Storage.getValue(key));
		assertNull_(Application.Storage.getValue(key + "_timestamp"));

		Application.Storage.setValue(key, 88);
		assertNull_(getValue(key, 1));
		assertNull_(Application.Storage.getValue(key));
		assertNull_(Application.Storage.getValue(key + "_timestamp"));

		return true;
	}

	(:test)
	function CacheRefreshValueTest(_logger as Test.Logger) as Lang.Boolean {
		var key = "cache_test_refresh";
		clearTestValue_(key);

		Application.Storage.setValue(key, 123);
		Application.Storage.setValue(key + "_timestamp", 1);
		Test.assertEqual(refreshValue(key), true);

		assertNumberEqual_(Application.Storage.getValue(key) as Lang.Number, 123);
		Test.assertEqual(
			(Application.Storage.getValue(key + "_timestamp") as Lang.Number) > 1,
			true
		);

		clearTestValue_(key);
		Test.assertEqual(refreshValue(key), false);
		return true;
	}
} // module Cache
