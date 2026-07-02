// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;

module Data {
	module Units {
		var is_24_hour as Lang.Boolean = false;

		var distance as System.UnitsSystem = System.UNIT_METRIC;
		var elevation as System.UnitsSystem = System.UNIT_METRIC;
		var height as System.UnitsSystem = System.UNIT_METRIC;
		var temperature as System.UnitsSystem = System.UNIT_METRIC;
		var weight as System.UnitsSystem = System.UNIT_METRIC;

		var meters_to_feet as Lang.Float = 3.28084;
		var meters_to_miles as Lang.Float = 0.000621371;
		var kg_to_lb as Lang.Float = 2.20462;

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
			return (_meters * meters_to_miles).toNumber();
		}

		function convertElevation(_meters as Lang.Number) as Lang.Number {
			if (elevation == System.UNIT_METRIC) {
				return _meters;
			}
			return (_meters * meters_to_feet).toNumber();
		}

		function convertHeight(_meters as Lang.Number) as Lang.Number {
			if (height == System.UNIT_METRIC) {
				return _meters;
			}
			return (_meters * meters_to_feet).toNumber();
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
	} // module Units
} // module Data
