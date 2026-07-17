// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

module Data {
	module Units {
		var is_24_hour as Lang.Boolean = false;

		var distance as System.UnitsSystem = System.UNIT_METRIC;
		var elevation as System.UnitsSystem = System.UNIT_METRIC;
		var height as System.UnitsSystem = System.UNIT_METRIC;
		var temperature as System.UnitsSystem = System.UNIT_METRIC;
		var weight as System.UnitsSystem = System.UNIT_METRIC;

		const METERS_TO_FEET as Lang.Float = 3.28084;
		const METERS_TO_MILES as Lang.Float = 0.000621371;
		const KG_TO_LB as Lang.Float = 2.20462;

		function refresh() as Void {
			var device_settings = System.getDeviceSettings();

			is_24_hour = device_settings.is24Hour;

			distance = device_settings.distanceUnits;
			elevation = device_settings.elevationUnits;
			height = device_settings.heightUnits;
			temperature = device_settings.temperatureUnits;
			weight = device_settings.weightUnits;
		}

		function convertHour(_hour as Lang.Number) as Lang.Number {
			if (is_24_hour) {
				return _hour;
			}

			_hour = _hour % 12;
			if (_hour == 0) {
				_hour = 12;
			}
			return _hour;
		}

		function getAmPm(_hour as Lang.Number) as Lang.String {
			if (is_24_hour) {
				return "";
			}
			return _hour < 12 ? "am" : "pm";
		}

		function convertDistance(_meters as Lang.Number) as Lang.Number {
			if (distance == System.UNIT_METRIC) {
				return _meters / 1000;
			}
			return (_meters * METERS_TO_MILES).toNumber();
		}

		function convertElevation(_meters as Lang.Number) as Lang.Number {
			if (elevation == System.UNIT_METRIC) {
				return _meters;
			}
			return (_meters * METERS_TO_FEET).toNumber();
		}

		function convertHeight(_meters as Lang.Number) as Lang.Number {
			if (height == System.UNIT_METRIC) {
				return _meters;
			}
			return (_meters * METERS_TO_FEET).toNumber();
		}

		function convertTemperature(
			_temperature_C as Lang.Number
		) as Lang.Number {
			if (temperature == System.UNIT_METRIC) {
				return _temperature_C;
			}
			return (_temperature_C * 1.8 + 32).toNumber();
		}

		function getTemperature() as Lang.String {
			if (temperature == System.UNIT_METRIC) {
				return "C";
			}
			return "F";
		}

		(:test)
		function UnitsHourConversionTest(_logger as Test.Logger) as Lang.Boolean {
			is_24_hour = false;
			Test.assertEqual(convertHour(0), 12);
			Test.assertEqual(convertHour(12), 12);
			Test.assertEqual(convertHour(15), 3);
			Test.assertEqual(getAmPm(11), "am");
			Test.assertEqual(getAmPm(12), "pm");

			is_24_hour = true;
			Test.assertEqual(convertHour(0), 0);
			Test.assertEqual(convertHour(15), 15);
			Test.assertEqual(getAmPm(15), "");

			return true;
		}

		(:test)
		function UnitsMetricConversionTest(
			_logger as Test.Logger
		) as Lang.Boolean {
			distance = System.UNIT_METRIC;
			elevation = System.UNIT_METRIC;
			height = System.UNIT_METRIC;
			temperature = System.UNIT_METRIC;

			Test.assertEqual(convertDistance(1234), 1);
			Test.assertEqual(convertElevation(321), 321);
			Test.assertEqual(convertHeight(180), 180);
			Test.assertEqual(convertTemperature(22), 22);
			Test.assertEqual(getTemperature(), "C");

			return true;
		}

		(:test)
		function UnitsImperialConversionTest(
			_logger as Test.Logger
		) as Lang.Boolean {
			distance = System.UNIT_STATUTE;
			elevation = System.UNIT_STATUTE;
			height = System.UNIT_STATUTE;
			temperature = System.UNIT_STATUTE;

			Test.assertEqual(convertDistance(1609), 0);
			Test.assertEqual(convertElevation(100), 328);
			Test.assertEqual(convertHeight(2), 6);
			Test.assertEqual(convertTemperature(0), 32);
			Test.assertEqual(getTemperature(), "F");

			return true;
		}
	} // module Units
} // module Data
