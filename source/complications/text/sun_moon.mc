// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;
import Toybox.Time;
import Toybox.Weather;

module Complication {

class SunMoon extends Text {
	static const MOON_PHASES = 16;

	hidden var moon_phase_ as Lang.Number = 0;

	function initialize() {
		Text.initialize(Complications.COMPLICATION_TYPE_SUNRISE);

		self.label_ = Lang.format("$1$     $2$", [
			"Dawn",
			"Dusk",
		]);

		self.value_bg_ = "00:00   00:00";

		self.justify_ = Graphics.TEXT_JUSTIFY_CENTER;

		self.small = true;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.value_ = self.getValue();
		self.moon_phase_ = getMoonPhase(Time.now());

		if (self.value_.length() != 0) {
			Cache.setValue("dawn_dusk", self.value_);
		} else {
			var data = Cache.getValue("dawn_dusk", 24);
			if (data != null) {
				self.value_ = data as Lang.String;
			}
		}
	}

	function render(_dc as Graphics.Dc) as Void {
		Text.render(_dc);

		var pos_x = self.pos_x;
		var pos_y = self.pos_y + Render.textSmallHeight(_dc) / 2;

		if (self.label_.length() != 0) {
			pos_y += (Render.labelHeight(_dc) + self.spacing_) / 2;
		}

		var is_new_moon = self.moon_phase_ == 0;
		var is_full_moon = self.moon_phase_ == (SunMoon.MOON_PHASES / 2);
		var moon_icon = "" + (Font.ICON_MOON_00 + self.moon_phase_);

		if (is_new_moon) {
			Render.icons(_dc, pos_x, pos_y, "", moon_icon);
		} else if (is_full_moon) {
			Render.iconsColor(_dc, pos_x, pos_y, moon_icon, Render.COLOR_FG);
			Render.iconsColor(_dc, pos_x +1, pos_y +1, moon_icon, Render.COLOR_FG);
		} else {
			Render.icons(_dc, pos_x, pos_y, moon_icon, moon_icon);
		}
	}

	function getValue() as Lang.String {
		var weather = Weather.getCurrentConditions();
		if (weather == null) {
			return "";
		}

		var location = weather.observationLocationPosition;
		if (location == null) {
			return "";
		}

		var now = Time.now();

		var sunrise = Weather.getSunrise(location, now);
		if (sunrise == null) {
			return "";
		}

		var sunset = Weather.getSunset(location, now);
		if (sunset == null) {
			return "";
		}

		var sunrise_info = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
		var sunrise_hour = Data.Units.convertHour(sunrise_info.hour);
		var sunrise_min = sunrise_info.min;
		var sunset_info = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);
		var sunset_hour = Data.Units.convertHour(sunset_info.hour);
		var sunset_min = sunset_info.min;

		return Lang.format("$1$:$2$   $3$:$4$", [
			sunrise_hour.format("%02d"),
			sunrise_min.format("%02d"),
			sunset_hour.format("%02d"),
			sunset_min.format("%02d"),
		]);
	}

	static function getMoonPhase(_moment as Time.Moment) as Lang.Number {
		var LUNAR_CYCLE_DAYS = 29.530588853;
		var SECONDS_PER_DAY = 86400;
		var NEW_MOON_REF = 947182440; // Jan 6, 2000 18:14 UTC

		var seconds_since = _moment.value() - NEW_MOON_REF;
		var days_since = seconds_since.toFloat() / SECONDS_PER_DAY;

		// Continuous phase in range [0, 1)
		var phase = days_since / LUNAR_CYCLE_DAYS;
		phase -= Math.floor(phase);

		// Center each phase in its bucket
		var phaseIndex = Math.floor((phase * SunMoon.MOON_PHASES) + 0.5).toNumber();

		// Wrap just in case
		if (phaseIndex == SunMoon.MOON_PHASES) {
			phaseIndex = 0;
		}

		return phaseIndex;
	}

	(:test)
	static function getMoonPhaseTest(_logger as Test.Logger) as Lang.Boolean {
		var one_day = new Time.Duration(24 * 60 * 60); // h * min * 60

		var new_moons = [
			Time.Gregorian.moment({
				:year  => 2000,
				:month => 1,
				:day   => 6,
				:hour  => 18,
				:min   => 14,
				:sec   => 0
			}),
			// Time.Gregorian.moment({
			// 	:year  => 2026,
			// 	:month => 2,
			// 	:day   => 17,
			// 	:hour  => 13,
			// 	:min   => 1,
			// 	:sec   => 0
			// }),
		];
		var new_moons_size = new_moons.size();

		var moon_phases = [
			/* day    phase */
			/*   0 */  0,
			/*   1 */  1,  1,
			/*   3 */  2,  2,
			/*   5 */  3,  3,
			/*   7 */  4,  4,
			/*   9 */  5,  5,
			/*  11 */  6,  6,
			/*  13 */  7,
			/*  14 */  8,  8,
			/*  16 */  9,  9,
			/*  17 */ 10, 10,
			/*  20 */ 11, 11,
			/*  22 */ 12, 12,
			/*  24 */ 13,
			/*  25 */ 14, 14,
			/*  27 */ 15, 15,
			/*  29 */  0,  0,
			/*   0 */  1,  1, 2,
		];
		var moon_phases_size = moon_phases.size();

		for (var i = 0; i < new_moons_size; ++i) {
			var new_moon = new_moons[i];

			for (var day = 0; day < moon_phases_size; ++day) {
				var moon_phase = moon_phases[day];

				_logger.debug(Lang.format(
					"[$1$] Day: $2$, Moon phase $3$", [
						i,
						day,
						moon_phase,
					]
				));

				Test.assertEqual(
					SunMoon.getMoonPhase(new_moon.add(one_day.multiply(day))),
					moon_phase
				);
			}
		}

		return true;
	}
}

} // module Complication
