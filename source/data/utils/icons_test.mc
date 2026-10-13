// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Lang;
import Toybox.Test;

module Data {
	(:test,:memory_not_low)
	function TemperatureIconThresholdTest(
		_logger as Test.Logger
	) as Lang.Boolean {
		var icon;
		icon = temperatureIcon(null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = temperatureIcon(-26);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_0);
		icon = temperatureIcon(-25);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_1);
		icon = temperatureIcon(-16);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_1);
		icon = temperatureIcon(-15);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_2);
		icon = temperatureIcon(-6);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_2);
		icon = temperatureIcon(-5);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_3);
		icon = temperatureIcon(4);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_3);
		icon = temperatureIcon(5);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_4);
		icon = temperatureIcon(14);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_4);
		icon = temperatureIcon(15);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_5);
		icon = temperatureIcon(24);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_5);
		icon = temperatureIcon(25);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_TEMPERATURE_6);
		return true;
	}

	(:test,:memory_not_low)
	function HumidityIconThresholdTest(_logger as Test.Logger) as Lang.Boolean {
		var icon;
		icon = humidityIcon(null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = humidityIcon(0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_0);
		icon = humidityIcon(24);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_0);
		icon = humidityIcon(25);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_1);
		icon = humidityIcon(29);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_1);
		icon = humidityIcon(30);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_2);
		icon = humidityIcon(59);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_2);
		icon = humidityIcon(60);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_3);
		icon = humidityIcon(69);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_3);
		icon = humidityIcon(70);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_4);
		icon = humidityIcon(100);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_HUMIDITY_4);
		return true;
	}

	(:test,:memory_not_low)
	function MoveBarIconLevelTest(_logger as Test.Logger) as Lang.Boolean {
		var icon;
		icon = moveBarIcon(null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = moveBarIcon(0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_MOVE_BAR_0);
		icon = moveBarIcon(1);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_MOVE_BAR_1);
		icon = moveBarIcon(2);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_MOVE_BAR_2);
		icon = moveBarIcon(3);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_MOVE_BAR_3);
		icon = moveBarIcon(4);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_MOVE_BAR_4);
		icon = moveBarIcon(5);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_MOVE_BAR_5);
		icon = moveBarIcon(-1);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = moveBarIcon(6);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		return true;
	}

	(:test,:memory_not_low)
	function BatteryIconThresholdTest(_logger as Test.Logger) as Lang.Boolean {
		var icon;
		icon = batteryIcon(null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = batteryIcon(0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_0);
		icon = batteryIcon(9);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_0);
		icon = batteryIcon(10);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_1);
		icon = batteryIcon(36);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_1);
		icon = batteryIcon(37);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_2);
		icon = batteryIcon(63);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_2);
		icon = batteryIcon(64);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_3);
		icon = batteryIcon(90);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_3);
		icon = batteryIcon(91);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_4);
		icon = batteryIcon(100);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_BATTERY_4);
		return true;
	}

	(:test,:memory_not_low)
	function SolarIntensityIconThresholdTest(
		_logger as Test.Logger
	) as Lang.Boolean {
		var icon;
		icon = solarIntensityIcon(null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = solarIntensityIcon(-1);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = solarIntensityIcon(0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_0);
		icon = solarIntensityIcon(19);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_0);
		icon = solarIntensityIcon(20);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_1);
		icon = solarIntensityIcon(39);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_1);
		icon = solarIntensityIcon(40);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_2);
		icon = solarIntensityIcon(59);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_2);
		icon = solarIntensityIcon(60);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_3);
		icon = solarIntensityIcon(79);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_3);
		icon = solarIntensityIcon(80);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_4);
		icon = solarIntensityIcon(100);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_4);
		return true;
	}

	(:test,:memory_low)
	function GeneralOnlyIconsTest(_logger as Test.Logger) as Lang.Boolean {
		var icon;
		icon = temperatureIcon(null);
		Test.assert(icon == null);
		icon = temperatureIcon(-26);
		Test.assert(icon == null);
		icon = temperatureIcon(25);
		Test.assert(icon == null);
		icon = humidityIcon(null);
		Test.assert(icon == null);
		icon = humidityIcon(0);
		Test.assert(icon == null);
		icon = humidityIcon(100);
		Test.assert(icon == null);
		icon = moveBarIcon(null);
		Test.assert(icon == null);
		icon = moveBarIcon(0);
		Test.assert(icon == null);
		icon = moveBarIcon(5);
		Test.assert(icon == null);
		icon = batteryIcon(null);
		Test.assert(icon == null);
		icon = batteryIcon(0);
		Test.assert(icon == null);
		icon = batteryIcon(100);
		Test.assert(icon == null);
		icon = solarIntensityIcon(0);
		Test.assert(icon == null);
		icon = solarIntensityIcon(100);
		Test.assert(icon == null);
		icon = rainIcon(100);
		Test.assert(icon == null);
		icon = uvIcon(10);
		Test.assert(icon == null);
		icon = windIcon(180, 10);
		Test.assert(icon == null);
		return true;
	}

	(:test,:memory_not_low)
	function WeatherIconThresholdTest(_logger as Test.Logger) as Lang.Boolean {
		var icon;
		icon = rainIcon(null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = rainIcon(20);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_RAIN_0);
		icon = rainIcon(21);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_RAIN_1);
		icon = rainIcon(50);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_RAIN_1);
		icon = rainIcon(51);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_RAIN_2);
		icon = rainIcon(80);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_RAIN_2);
		icon = rainIcon(81);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_RAIN_3);
		icon = uvIcon(null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = uvIcon(1);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_0);
		icon = uvIcon(2);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_1);
		icon = uvIcon(5);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_2);
		icon = uvIcon(7);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_3);
		icon = uvIcon(9);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_SOLAR_4);
		icon = windIcon(null, null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = windIcon(null, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = windIcon(null, 10);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_NONE);
		icon = windIcon(0, null);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_N_0);
		icon = windIcon(0, 2);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_N_0);
		icon = windIcon(0, 3);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_N_1);
		icon = windIcon(0, 6);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_N_1);
		icon = windIcon(0, 7);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_N_2);
		icon = windIcon(22, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_N_0);
		icon = windIcon(23, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_NE_0);
		icon = windIcon(90, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_E_0);
		icon = windIcon(135, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_SE_0);
		icon = windIcon(180, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_S_0);
		icon = windIcon(225, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_SW_0);
		icon = windIcon(270, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_W_0);
		icon = windIcon(315, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_NW_0);
		icon = windIcon(338, 0);
		Test.assert(icon != null);
		Test.assertEqual(icon as Lang.String, Fonts.ICON_WIND_N_0);
		return true;
	}
} // module Data
