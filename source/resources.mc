// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

module Resources {

const CONDITIONS as Lang.Array<Lang.String> = [
	Application.loadResource(Rez.Strings.CONDITION_00_CLEAR) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_01_PARTLY_CLOUDY) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_02_MOSTLY_CLOUDY) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_03_RAIN) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_04_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_05_WINDY) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_06_THUNDERSTORMS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_07_WINTRY_MIX) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_08_FOG) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_09_HAZY) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_10_HAIL) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_11_SCATTERED_SHOWERS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_12_SCATTERED_THUNDERSTORMS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_13_UNKNOWN_PRECIPITATION) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_14_LIGHT_RAIN) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_15_HEAVY_RAIN) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_16_LIGHT_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_17_HEAVY_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_18_LIGHT_RAIN_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_19_HEAVY_RAIN_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_20_CLOUDY) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_21_RAIN_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_22_PARTLY_CLEAR) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_23_MOSTLY_CLEAR) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_24_LIGHT_SHOWERS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_25_SHOWERS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_26_HEAVY_SHOWERS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_27_CHANCE_OF_SHOWERS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_28_CHANCE_OF_THUNDERSTORMS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_29_MIST) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_30_DUST) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_31_DRIZZLE) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_32_TORNADO) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_33_SMOKE) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_34_ICE) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_35_SAND) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_36_SQUALL) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_37_SANDSTORM) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_38_VOLCANIC_ASH) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_39_HAZE) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_40_FAIR) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_41_HURRICANE) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_42_TROPICAL_STORM) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_43_CHANCE_OF_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_44_CHANCE_OF_RAIN_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_45_CLOUDY_CHANCE_OF_RAIN) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_46_CLOUDY_CHANCE_OF_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_47_CLOUDY_CHANCE_OF_RAIN_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_48_FLURRIES) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_49_FREEZING_RAIN) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_50_SLEET) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_51_ICE_SNOW) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_52_THIN_CLOUDS) as Lang.String,
	Application.loadResource(Rez.Strings.CONDITION_53_UNKNOWN) as Lang.String,
];

const DAYS_OF_WEEK as Lang.Array<Lang.String> = [
	"1-based",
	Application.loadResource(Rez.Strings.DAY_OF_WEEK_01_SUN) as Lang.String,
	Application.loadResource(Rez.Strings.DAY_OF_WEEK_02_MON) as Lang.String,
	Application.loadResource(Rez.Strings.DAY_OF_WEEK_03_TUE) as Lang.String,
	Application.loadResource(Rez.Strings.DAY_OF_WEEK_04_WED) as Lang.String,
	Application.loadResource(Rez.Strings.DAY_OF_WEEK_05_THU) as Lang.String,
	Application.loadResource(Rez.Strings.DAY_OF_WEEK_06_FRI) as Lang.String,
	Application.loadResource(Rez.Strings.DAY_OF_WEEK_07_SAT) as Lang.String,
];

const MONTHS as Lang.Array<Lang.String> = [
	"1-based",
	Application.loadResource(Rez.Strings.MONTH_01_JAN) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_02_FEB) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_03_MAR) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_04_APR) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_05_MAY) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_06_JUN) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_07_JUL) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_08_AUG) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_09_SEP) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_10_OCT) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_11_NOV) as Lang.String,
	Application.loadResource(Rez.Strings.MONTH_12_DEC) as Lang.String,
];

(:test)
function VerifyGlyphs(logger as Test.Logger) as Lang.Boolean {
	var collections = [
		CONDITIONS, DAYS_OF_WEEK, MONTHS
	];

	for (var i = 0; i < collections.size(); ++i) {
		var collection = collections[i];

		for (var j = 0; j < collection.size(); ++j) {
			var entry = collection[j].toCharArray();

			for (var k = 0; k < entry.size(); ++k) {
				var char = entry[k];

				Font.TYPEFACE.getOrEmpty(char);
			}
		}
	}

	var digits = ":0123456789".toCharArray();
	for (var i = 0; i < digits.size(); ++i) {
		var digit = digits[i];

		Font.TYPEFACE.getOrEmpty(digit);
		Font.DIGITS.getOrEmpty(digit);
		Font.DIGITS_BLURED.getOrEmpty(digit);
	}

	return true;
}

} // module Resources
