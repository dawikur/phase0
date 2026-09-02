// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

module Resources {
	function get(_id as Lang.ResourceId) as Lang.String {
		return Application.loadResource(_id) as Lang.String;
	}

	function getBounded_(
		_ids as Lang.Array<Lang.ResourceId>,
		_id as Lang.Number,
		_fallback_id as Lang.Number
	) as Lang.String {
		var id = _id;
		if (id < 0 or _ids.size() <= id) {
			id = _fallback_id;
		}
		return get(_ids[id]);
	}

	const CONDITIONS as Lang.Array<Lang.ResourceId> = [
		Rez.Strings.CONDITION_00_CLEAR,
		Rez.Strings.CONDITION_01_PARTLY_CLOUDY,
		Rez.Strings.CONDITION_02_MOSTLY_CLOUDY,
		Rez.Strings.CONDITION_03_RAIN,
		Rez.Strings.CONDITION_04_SNOW,
		Rez.Strings.CONDITION_05_WINDY,
		Rez.Strings.CONDITION_06_THUNDERSTORMS,
		Rez.Strings.CONDITION_07_WINTRY_MIX,
		Rez.Strings.CONDITION_08_FOG,
		Rez.Strings.CONDITION_09_HAZY,
		Rez.Strings.CONDITION_10_HAIL,
		Rez.Strings.CONDITION_11_SCATTERED_SHOWERS,
		Rez.Strings.CONDITION_12_SCATTERED_THUNDERSTORMS,
		Rez.Strings.CONDITION_13_UNKNOWN_PRECIPITATION,
		Rez.Strings.CONDITION_14_LIGHT_RAIN,
		Rez.Strings.CONDITION_15_HEAVY_RAIN,
		Rez.Strings.CONDITION_16_LIGHT_SNOW,
		Rez.Strings.CONDITION_17_HEAVY_SNOW,
		Rez.Strings.CONDITION_18_LIGHT_RAIN_SNOW,
		Rez.Strings.CONDITION_19_HEAVY_RAIN_SNOW,
		Rez.Strings.CONDITION_20_CLOUDY,
		Rez.Strings.CONDITION_21_RAIN_SNOW,
		Rez.Strings.CONDITION_22_PARTLY_CLEAR,
		Rez.Strings.CONDITION_23_MOSTLY_CLEAR,
		Rez.Strings.CONDITION_24_LIGHT_SHOWERS,
		Rez.Strings.CONDITION_25_SHOWERS,
		Rez.Strings.CONDITION_26_HEAVY_SHOWERS,
		Rez.Strings.CONDITION_27_CHANCE_OF_SHOWERS,
		Rez.Strings.CONDITION_28_CHANCE_OF_THUNDERSTORMS,
		Rez.Strings.CONDITION_29_MIST,
		Rez.Strings.CONDITION_30_DUST,
		Rez.Strings.CONDITION_31_DRIZZLE,
		Rez.Strings.CONDITION_32_TORNADO,
		Rez.Strings.CONDITION_33_SMOKE,
		Rez.Strings.CONDITION_34_ICE,
		Rez.Strings.CONDITION_35_SAND,
		Rez.Strings.CONDITION_36_SQUALL,
		Rez.Strings.CONDITION_37_SANDSTORM,
		Rez.Strings.CONDITION_38_VOLCANIC_ASH,
		Rez.Strings.CONDITION_39_HAZE,
		Rez.Strings.CONDITION_40_FAIR,
		Rez.Strings.CONDITION_41_HURRICANE,
		Rez.Strings.CONDITION_42_TROPICAL_STORM,
		Rez.Strings.CONDITION_43_CHANCE_OF_SNOW,
		Rez.Strings.CONDITION_44_CHANCE_OF_RAIN_SNOW,
		Rez.Strings.CONDITION_45_CLOUDY_CHANCE_OF_RAIN,
		Rez.Strings.CONDITION_46_CLOUDY_CHANCE_OF_SNOW,
		Rez.Strings.CONDITION_47_CLOUDY_CHANCE_OF_RAIN_SNOW,
		Rez.Strings.CONDITION_48_FLURRIES,
		Rez.Strings.CONDITION_49_FREEZING_RAIN,
		Rez.Strings.CONDITION_50_SLEET,
		Rez.Strings.CONDITION_51_ICE_SNOW,
		Rez.Strings.CONDITION_52_THIN_CLOUDS,
		Rez.Strings.CONDITION_53_UNKNOWN,
	];

	function getCondition(_id as Lang.Number) as Lang.String {
		return getBounded_(CONDITIONS, _id, 53);
	}

	const CONDITIONS_SHORT as Lang.Array<Lang.ResourceId> = [
		Rez.Strings.CONDITION_00_CLEAR,
		Rez.Strings.CONDITION_20_CLOUDY,
		Rez.Strings.CONDITION_20_CLOUDY,
		Rez.Strings.CONDITION_03_RAIN,
		Rez.Strings.CONDITION_04_SNOW,
		Rez.Strings.CONDITION_05_WINDY,
		Rez.Strings.CONDITION_06_THUNDERSTORMS,
		Rez.Strings.CONDITION_07_WINTRY_MIX,
		Rez.Strings.CONDITION_08_FOG,
		Rez.Strings.CONDITION_09_HAZY,
		Rez.Strings.CONDITION_10_HAIL,
		Rez.Strings.CONDITION_25_SHOWERS,
		Rez.Strings.CONDITION_06_THUNDERSTORMS,
		Rez.Strings.CONDITION_53_UNKNOWN,
		Rez.Strings.CONDITION_03_RAIN,
		Rez.Strings.CONDITION_03_RAIN,
		Rez.Strings.CONDITION_04_SNOW,
		Rez.Strings.CONDITION_04_SNOW,
		Rez.Strings.CONDITION_21_RAIN_SNOW,
		Rez.Strings.CONDITION_21_RAIN_SNOW,
		Rez.Strings.CONDITION_20_CLOUDY,
		Rez.Strings.CONDITION_21_RAIN_SNOW,
		Rez.Strings.CONDITION_00_CLEAR,
		Rez.Strings.CONDITION_00_CLEAR,
		Rez.Strings.CONDITION_25_SHOWERS,
		Rez.Strings.CONDITION_25_SHOWERS,
		Rez.Strings.CONDITION_25_SHOWERS,
		Rez.Strings.CONDITION_25_SHOWERS,
		Rez.Strings.CONDITION_06_THUNDERSTORMS,
		Rez.Strings.CONDITION_29_MIST,
		Rez.Strings.CONDITION_30_DUST,
		Rez.Strings.CONDITION_31_DRIZZLE,
		Rez.Strings.CONDITION_32_TORNADO,
		Rez.Strings.CONDITION_33_SMOKE,
		Rez.Strings.CONDITION_34_ICE,
		Rez.Strings.CONDITION_35_SAND,
		Rez.Strings.CONDITION_36_SQUALL,
		Rez.Strings.CONDITION_37_SANDSTORM,
		Rez.Strings.CONDITION_38_VOLCANIC_ASH,
		Rez.Strings.CONDITION_39_HAZE,
		Rez.Strings.CONDITION_40_FAIR,
		Rez.Strings.CONDITION_41_HURRICANE,
		Rez.Strings.CONDITION_06_THUNDERSTORMS,
		Rez.Strings.CONDITION_04_SNOW,
		Rez.Strings.CONDITION_21_RAIN_SNOW,
		Rez.Strings.CONDITION_03_RAIN,
		Rez.Strings.CONDITION_04_SNOW,
		Rez.Strings.CONDITION_21_RAIN_SNOW,
		Rez.Strings.CONDITION_48_FLURRIES,
		Rez.Strings.CONDITION_03_RAIN,
		Rez.Strings.CONDITION_50_SLEET,
		Rez.Strings.CONDITION_51_ICE_SNOW,
		Rez.Strings.CONDITION_20_CLOUDY,
		Rez.Strings.CONDITION_53_UNKNOWN,
	];

	function getConditionShort(_id as Lang.Number) as Lang.String {
		return getBounded_(CONDITIONS_SHORT, _id, 53);
	}

	const DAYS_OF_WEEK as Lang.Array<Lang.ResourceId> = [
		new Lang.ResourceId(), // 1-based
		Rez.Strings.DAY_OF_WEEK_01_SUN,
		Rez.Strings.DAY_OF_WEEK_02_MON,
		Rez.Strings.DAY_OF_WEEK_03_TUE,
		Rez.Strings.DAY_OF_WEEK_04_WED,
		Rez.Strings.DAY_OF_WEEK_05_THU,
		Rez.Strings.DAY_OF_WEEK_06_FRI,
		Rez.Strings.DAY_OF_WEEK_07_SAT,
	];

	function getDayOfWeek(_id as Lang.Number) as Lang.String {
		return getBounded_(DAYS_OF_WEEK, _id, 1);
	}

	const MONTHS as Lang.Array<Lang.ResourceId> = [
		new Lang.ResourceId(), // 1-based
		Rez.Strings.MONTH_01_JAN,
		Rez.Strings.MONTH_02_FEB,
		Rez.Strings.MONTH_03_MAR,
		Rez.Strings.MONTH_04_APR,
		Rez.Strings.MONTH_05_MAY,
		Rez.Strings.MONTH_06_JUN,
		Rez.Strings.MONTH_07_JUL,
		Rez.Strings.MONTH_08_AUG,
		Rez.Strings.MONTH_09_SEP,
		Rez.Strings.MONTH_10_OCT,
		Rez.Strings.MONTH_11_NOV,
		Rez.Strings.MONTH_12_DEC,
	];

	function getMonth(_id as Lang.Number) as Lang.String {
		return getBounded_(MONTHS, _id, 1);
	}
} // module Resources
