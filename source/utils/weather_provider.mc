// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

module WeatherProvider {
	const CACHE_TTL_HOURS as Lang.Number = 48;

	var last_refresh_hour as Lang.Number = -1;

	var condition as Lang.Number? = null;
	var precipitation_chance as Lang.Number? = null;
	var temperature as Lang.Number? = null;
	var uv_index as Lang.Number? = null;
	var wind_bearing as Lang.Number? = null;
	var wind_speed as Lang.Number? = null;

	function refresh(_hour as Lang.Number) as Void {
		if (last_refresh_hour == _hour) {
			return;
		}

		var weather = Weather.getCurrentConditions();
		if (weather == null) {
			return;
		}

		last_refresh_hour = _hour;

		condition = refreshOne_("condition", weather.condition);
		precipitation_chance = refreshOne_(
			"precipitation_chance",
			weather.precipitationChance
		);
		temperature = refreshOne_("temperature", weather.temperature);
		if (weather has :uvIndex) {
			uv_index = refreshOne_("uv_index", weather.uvIndex);
		}
		wind_bearing = refreshOne_("wind_bearing", weather.windBearing);
		wind_speed = refreshOne_("wind_speed", weather.windSpeed);
	}

	function refreshOne_(
		_name as Lang.String,
		_data_maybe as Lang.Numeric?
	) as Lang.Number? {
		if (_data_maybe != null) {
			var data = (_data_maybe as Lang.Numeric).toNumber();
			Cache.setValue(_name, data);
			return data;
		}

		var cached = Cache.getValue(_name, CACHE_TTL_HOURS);
		if (cached != null) {
			return cached as Lang.Number;
		}

		return null;
	}
} // module WeatherProvider
