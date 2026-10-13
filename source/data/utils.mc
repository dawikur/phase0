// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;
import Toybox.Test;

module Data {
	function temperatureIcon(_temperature_c as Lang.Number?) as Lang.String {
		if (_temperature_c == null) {
			return Fonts.ICON_NONE;
		}
		if (_temperature_c < -25) {
			return Fonts.ICON_TEMPERATURE_0;
		}
		if (_temperature_c < -15) {
			return Fonts.ICON_TEMPERATURE_1;
		}
		if (_temperature_c < -5) {
			return Fonts.ICON_TEMPERATURE_2;
		}
		if (_temperature_c < 5) {
			return Fonts.ICON_TEMPERATURE_3;
		}
		if (_temperature_c < 15) {
			return Fonts.ICON_TEMPERATURE_4;
		}
		if (_temperature_c < 25) {
			return Fonts.ICON_TEMPERATURE_5;
		}
		return Fonts.ICON_TEMPERATURE_6;
	}

	(:test)
	function TemperatureIconThresholdTest(_logger as Test.Logger) as Lang.Boolean {
		Test.assertEqual(temperatureIcon(null), Fonts.ICON_NONE);
		Test.assertEqual(temperatureIcon(-26), Fonts.ICON_TEMPERATURE_0);
		Test.assertEqual(temperatureIcon(-25), Fonts.ICON_TEMPERATURE_1);
		Test.assertEqual(temperatureIcon(-16), Fonts.ICON_TEMPERATURE_1);
		Test.assertEqual(temperatureIcon(-15), Fonts.ICON_TEMPERATURE_2);
		Test.assertEqual(temperatureIcon(-6), Fonts.ICON_TEMPERATURE_2);
		Test.assertEqual(temperatureIcon(-5), Fonts.ICON_TEMPERATURE_3);
		Test.assertEqual(temperatureIcon(4), Fonts.ICON_TEMPERATURE_3);
		Test.assertEqual(temperatureIcon(5), Fonts.ICON_TEMPERATURE_4);
		Test.assertEqual(temperatureIcon(14), Fonts.ICON_TEMPERATURE_4);
		Test.assertEqual(temperatureIcon(15), Fonts.ICON_TEMPERATURE_5);
		Test.assertEqual(temperatureIcon(24), Fonts.ICON_TEMPERATURE_5);
		Test.assertEqual(temperatureIcon(25), Fonts.ICON_TEMPERATURE_6);
		return true;
	}

	function humidityIcon(_humidity as Lang.Number?) as Lang.String {
		if (_humidity == null) {
			return Fonts.ICON_NONE;
		}
		if (_humidity < 25) {
			return Fonts.ICON_HUMIDITY_0;
		}
		if (_humidity < 30) {
			return Fonts.ICON_HUMIDITY_1;
		}
		if (_humidity < 60) {
			return Fonts.ICON_HUMIDITY_2;
		}
		if (_humidity < 70) {
			return Fonts.ICON_HUMIDITY_3;
		}
		return Fonts.ICON_HUMIDITY_4;
	}

	(:test)
	function HumidityIconThresholdTest(_logger as Test.Logger) as Lang.Boolean {
		Test.assertEqual(humidityIcon(null), Fonts.ICON_NONE);
		Test.assertEqual(humidityIcon(0), Fonts.ICON_HUMIDITY_0);
		Test.assertEqual(humidityIcon(24), Fonts.ICON_HUMIDITY_0);
		Test.assertEqual(humidityIcon(25), Fonts.ICON_HUMIDITY_1);
		Test.assertEqual(humidityIcon(29), Fonts.ICON_HUMIDITY_1);
		Test.assertEqual(humidityIcon(30), Fonts.ICON_HUMIDITY_2);
		Test.assertEqual(humidityIcon(59), Fonts.ICON_HUMIDITY_2);
		Test.assertEqual(humidityIcon(60), Fonts.ICON_HUMIDITY_3);
		Test.assertEqual(humidityIcon(69), Fonts.ICON_HUMIDITY_3);
		Test.assertEqual(humidityIcon(70), Fonts.ICON_HUMIDITY_4);
		Test.assertEqual(humidityIcon(100), Fonts.ICON_HUMIDITY_4);
		return true;
	}

	function moveBarIcon(_level as Lang.Number?) as Lang.String {
		if (_level == null) {
			return Fonts.ICON_NONE;
		}
		switch (_level) {
			case 0:
				return Fonts.ICON_MOVE_BAR_0;
			case 1:
				return Fonts.ICON_MOVE_BAR_1;
			case 2:
				return Fonts.ICON_MOVE_BAR_2;
			case 3:
				return Fonts.ICON_MOVE_BAR_3;
			case 4:
				return Fonts.ICON_MOVE_BAR_4;
			case 5:
				return Fonts.ICON_MOVE_BAR_5;
		}
		return Fonts.ICON_NONE;
	}

	(:test)
	function MoveBarIconLevelTest(_logger as Test.Logger) as Lang.Boolean {
		Test.assertEqual(moveBarIcon(null), Fonts.ICON_NONE);
		Test.assertEqual(moveBarIcon(0), Fonts.ICON_MOVE_BAR_0);
		Test.assertEqual(moveBarIcon(1), Fonts.ICON_MOVE_BAR_1);
		Test.assertEqual(moveBarIcon(2), Fonts.ICON_MOVE_BAR_2);
		Test.assertEqual(moveBarIcon(3), Fonts.ICON_MOVE_BAR_3);
		Test.assertEqual(moveBarIcon(4), Fonts.ICON_MOVE_BAR_4);
		Test.assertEqual(moveBarIcon(5), Fonts.ICON_MOVE_BAR_5);
		Test.assertEqual(moveBarIcon(-1), Fonts.ICON_NONE);
		Test.assertEqual(moveBarIcon(6), Fonts.ICON_NONE);
		return true;
	}

	function batteryIcon(_percentage as Lang.Number?) as Lang.String {
		if (_percentage == null) {
			return Fonts.ICON_NONE;
		}
		if (_percentage < 10) {
			return Fonts.ICON_BATTERY_0;
		}
		if (_percentage < 37) {
			return Fonts.ICON_BATTERY_1;
		}
		if (_percentage < 64) {
			return Fonts.ICON_BATTERY_2;
		}
		if (_percentage <= 90) {
			return Fonts.ICON_BATTERY_3;
		}
		return Fonts.ICON_BATTERY_4;
	}

	(:test)
	function BatteryIconThresholdTest(_logger as Test.Logger) as Lang.Boolean {
		Test.assertEqual(batteryIcon(null), Fonts.ICON_NONE);
		Test.assertEqual(batteryIcon(0), Fonts.ICON_BATTERY_0);
		Test.assertEqual(batteryIcon(9), Fonts.ICON_BATTERY_0);
		Test.assertEqual(batteryIcon(10), Fonts.ICON_BATTERY_1);
		Test.assertEqual(batteryIcon(36), Fonts.ICON_BATTERY_1);
		Test.assertEqual(batteryIcon(37), Fonts.ICON_BATTERY_2);
		Test.assertEqual(batteryIcon(63), Fonts.ICON_BATTERY_2);
		Test.assertEqual(batteryIcon(64), Fonts.ICON_BATTERY_3);
		Test.assertEqual(batteryIcon(90), Fonts.ICON_BATTERY_3);
		Test.assertEqual(batteryIcon(91), Fonts.ICON_BATTERY_4);
		Test.assertEqual(batteryIcon(100), Fonts.ICON_BATTERY_4);
		return true;
	}

	function solarIntensityIcon(_intensity as Lang.Number?) as Lang.String {
		if (_intensity == null or _intensity < 0) {
			return Fonts.ICON_NONE;
		}
		if (_intensity < 20) {
			return Fonts.ICON_SOLAR_0;
		}
		if (_intensity < 40) {
			return Fonts.ICON_SOLAR_1;
		}
		if (_intensity < 60) {
			return Fonts.ICON_SOLAR_2;
		}
		if (_intensity < 80) {
			return Fonts.ICON_SOLAR_3;
		}
		return Fonts.ICON_SOLAR_4;
	}

	(:test)
	function SolarIntensityIconThresholdTest(_logger as Test.Logger) as Lang.Boolean {
		Test.assertEqual(solarIntensityIcon(null), Fonts.ICON_NONE);
		Test.assertEqual(solarIntensityIcon(-1), Fonts.ICON_NONE);
		Test.assertEqual(solarIntensityIcon(0), Fonts.ICON_SOLAR_0);
		Test.assertEqual(solarIntensityIcon(19), Fonts.ICON_SOLAR_0);
		Test.assertEqual(solarIntensityIcon(20), Fonts.ICON_SOLAR_1);
		Test.assertEqual(solarIntensityIcon(39), Fonts.ICON_SOLAR_1);
		Test.assertEqual(solarIntensityIcon(40), Fonts.ICON_SOLAR_2);
		Test.assertEqual(solarIntensityIcon(59), Fonts.ICON_SOLAR_2);
		Test.assertEqual(solarIntensityIcon(60), Fonts.ICON_SOLAR_3);
		Test.assertEqual(solarIntensityIcon(79), Fonts.ICON_SOLAR_3);
		Test.assertEqual(solarIntensityIcon(80), Fonts.ICON_SOLAR_4);
		Test.assertEqual(solarIntensityIcon(100), Fonts.ICON_SOLAR_4);
		return true;
	}

	module RefreshRate {
		const NONE = 0;
		const HOUR = 1;
		const MIN = 2;
		const SEC = 3;
	} // module RefreshRate
} // module Data
