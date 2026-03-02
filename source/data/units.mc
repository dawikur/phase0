// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.System;
import Toybox.Lang;

module Data {
module Units {

class Settings {
	var is_24_hour as Lang.Boolean;

	var distance as System.UnitsSystem;
	var elevation as System.UnitsSystem;
	var height as System.UnitsSystem;
	var temperature as System.UnitsSystem;
	var weight as System.UnitsSystem;

	var meters_to_feet as Lang.Float = 3.28084;
	var meters_to_miles as Lang.Float = 0.000621371;
	var kg_to_lb as Lang.Float = 2.20462;

	function initialize() {
		var device_settings = System.getDeviceSettings();

		self.is_24_hour = device_settings.is24Hour;

		self.distance = device_settings.distanceUnits;
		self.elevation = device_settings.elevationUnits;
		self.height = device_settings.heightUnits;
		self.temperature = device_settings.temperatureUnits;
		self.weight = device_settings.weightUnits;
	}
}

const SETTINGS as Settings = new Settings();

function convertHour(_hour as Lang.Number) as Lang.Number {
	if (SETTINGS.is_24_hour) {
		return _hour;
	}

	_hour = _hour % 12;
	if (_hour == 0) {
		_hour = 12;
	}
	return _hour;
}

function getAmPm(_hour as Lang.Number) as Lang.String {
	if (SETTINGS.is_24_hour) {
		return "";
	}
	return _hour < 12 ? "am" : "pm";
}

function convertDistance(_meters as Lang.Number) as Lang.Number {
	if (SETTINGS.distance == System.UNIT_METRIC) {
		return _meters / 1000;
	}
	return (_meters * SETTINGS.meters_to_miles).toNumber();
}

function convertElevation(_meters as Lang.Number) as Lang.Number {
	if (SETTINGS.elevation == System.UNIT_METRIC) {
		return _meters;
	}
	return (_meters * SETTINGS.meters_to_feet).toNumber();
}

function convertHeight(_meters as Lang.Number) as Lang.Number {
	if (SETTINGS.height == System.UNIT_METRIC) {
		return _meters;
	}
	return (_meters * SETTINGS.meters_to_feet).toNumber();
}

function convertTemperature(_temperature_C as Lang.Number) as Lang.Number {
	if (SETTINGS.temperature == System.UNIT_METRIC) {
		return _temperature_C;
	}
	return ((_temperature_C * 1.8) + 32).toNumber();
}

function getTemperature() as Lang.String {
	if (SETTINGS.temperature == System.UNIT_METRIC) {
		return "C";
	}
	return "F";
}

} // module Units
} // module Data
