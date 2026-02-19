// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.Weather;

module Complication {

class Weather extends Text {
	hidden var units_system_ as System.UnitsSystem;

	function initialize() {
		Text.initialize(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);

		self.justify_ = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

		var device_settings = System.getDeviceSettings();
		self.units_system_ = device_settings.distanceUnits;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var weather = Weather.getCurrentConditions();
		if (weather != null) {
			var text = "";
			var temp = "";

			if (weather.condition != null) {
				var condition = weather.condition as Lang.Number;

				text = Application.loadResource(Resources.CONDITIONS[condition]) as Lang.String;
			}

			if (weather.temperature != null) {
				var temperature = weather.temperature as Lang.Numeric;
				var unit = "C";

				if (self.units_system_ == System.UNIT_STATUTE) {
					temperature = (temperature * 1.8) + 32;
					unit = "F";
				}

				temp = temperature.toNumber().format("%d") + unit;
			}

			var value = text + "  " + temp;
			if (Render.textWidth(_dc, value) <= self.size_x) {
				self.value_ = value;
			} else {
				text = getShorterCondition(text);
				value = text + "  " + temp;

				if (Render.textWidth(_dc, value) <= self.size_x) {
					self.value_ = value;
				} else {
					self.value_ = temp;
				}
			}
		}

		if (self.value_.length() != 0) {
			Cache.setValue("weather", self.value_);
		} else {
			var data = Cache.getValue("weather", 8); // 8 hours
			if (data != null) {
				self.value_ = data as Lang.String;
			}
		}
	}

	static function getShorterCondition(_str as Lang.String) as Lang.String {
		var space = _str.find(" ");
		var poss = _str.find(" poss.");

		if (space == null or space == poss) {
			space = 0;
		}
		if (space != 0) {
			++space;
		}

		return _str.substring(
			space,
			poss
		) + (poss == null ? "" : "?");
	}

	(:test)
	static function getShorterConditionTest(_logger as Test.Logger) as Lang.Boolean {
		var data = {
			Rez.Strings.CONDITION_00_CLEAR => "Clear",
			Rez.Strings.CONDITION_01_PARTLY_CLOUDY => "Cloudy",
			Rez.Strings.CONDITION_02_MOSTLY_CLOUDY => "Cloudy",
			Rez.Strings.CONDITION_03_RAIN => "Rain",
			Rez.Strings.CONDITION_04_SNOW => "Snow",
			Rez.Strings.CONDITION_05_WINDY => "Windy",
			Rez.Strings.CONDITION_06_THUNDERSTORMS => "Storms",
			Rez.Strings.CONDITION_07_WINTRY_MIX => "Wintry",
			Rez.Strings.CONDITION_08_FOG => "Fog",
			Rez.Strings.CONDITION_09_HAZY => "Hazy",
			Rez.Strings.CONDITION_10_HAIL => "Hail",
			Rez.Strings.CONDITION_11_SCATTERED_SHOWERS => "Showers",
			Rez.Strings.CONDITION_12_SCATTERED_THUNDERSTORMS => "Storms",
			Rez.Strings.CONDITION_13_UNKNOWN_PRECIPITATION => "Precip",
			Rez.Strings.CONDITION_14_LIGHT_RAIN => "Rain",
			Rez.Strings.CONDITION_15_HEAVY_RAIN => "Rain",
			Rez.Strings.CONDITION_16_LIGHT_SNOW => "Snow",
			Rez.Strings.CONDITION_17_HEAVY_SNOW => "Snow",
			Rez.Strings.CONDITION_18_LIGHT_RAIN_SNOW => "Rain/Snow",
			Rez.Strings.CONDITION_19_HEAVY_RAIN_SNOW => "Rain/Snow",
			Rez.Strings.CONDITION_20_CLOUDY => "Cloudy",
			Rez.Strings.CONDITION_21_RAIN_SNOW => "Rain/Snow",
			Rez.Strings.CONDITION_22_PARTLY_CLEAR => "Clear",
			Rez.Strings.CONDITION_23_MOSTLY_CLEAR => "Clear",
			Rez.Strings.CONDITION_24_LIGHT_SHOWERS => "Showers",
			Rez.Strings.CONDITION_25_SHOWERS => "Showers",
			Rez.Strings.CONDITION_26_HEAVY_SHOWERS => "Showers",
			Rez.Strings.CONDITION_27_CHANCE_OF_SHOWERS => "Showers?",
			Rez.Strings.CONDITION_28_CHANCE_OF_THUNDERSTORMS => "Storms?",
			Rez.Strings.CONDITION_29_MIST => "Mist",
			Rez.Strings.CONDITION_30_DUST => "Dust",
			Rez.Strings.CONDITION_31_DRIZZLE => "Drizzle",
			Rez.Strings.CONDITION_32_TORNADO => "Tornado",
			Rez.Strings.CONDITION_33_SMOKE => "Smoke",
			Rez.Strings.CONDITION_34_ICE => "Ice",
			Rez.Strings.CONDITION_35_SAND => "Sand",
			Rez.Strings.CONDITION_36_SQUALL => "Squall",
			Rez.Strings.CONDITION_37_SANDSTORM => "Sandstorm",
			Rez.Strings.CONDITION_38_VOLCANIC_ASH => "Ash",
			Rez.Strings.CONDITION_39_HAZE => "Haze",
			Rez.Strings.CONDITION_40_FAIR => "Fair",
			Rez.Strings.CONDITION_41_HURRICANE => "Hurricane",
			Rez.Strings.CONDITION_42_TROPICAL_STORM => "Storm",
			Rez.Strings.CONDITION_43_CHANCE_OF_SNOW => "Snow?",
			Rez.Strings.CONDITION_44_CHANCE_OF_RAIN_SNOW => "Rain/Snow?",
			Rez.Strings.CONDITION_45_CLOUDY_CHANCE_OF_RAIN => "Rain?",
			Rez.Strings.CONDITION_46_CLOUDY_CHANCE_OF_SNOW => "Snow?",
			Rez.Strings.CONDITION_47_CLOUDY_CHANCE_OF_RAIN_SNOW => "Rain/Snow?",
			Rez.Strings.CONDITION_48_FLURRIES => "Flurries",
			Rez.Strings.CONDITION_49_FREEZING_RAIN => "Rain",
			Rez.Strings.CONDITION_50_SLEET => "Sleet",
			Rez.Strings.CONDITION_51_ICE_SNOW => "Ice/Snow",
			Rez.Strings.CONDITION_52_THIN_CLOUDS => "Clouds",
			Rez.Strings.CONDITION_53_UNKNOWN => "Unknown",
		};

		var labels = data.keys();
		var labels_size = labels.size();
		for (var i = 0; i < labels_size; ++i) {
			var label = labels[i];
			var expected_short_str = data.get(label) as Lang.String;

			var long_str = Application.loadResource(label as Lang.ResourceId) as Lang.String;
			var short_str = getShorterCondition(long_str);

			_logger.debug(Lang.format(
				"[$1$] '$2$' =?= '$3$'", [
					long_str,
					expected_short_str,
					short_str
				]
			));

			Test.assertEqual(
				expected_short_str,
				short_str
			);
		}

		return true;
	}
}

} // module Complication
