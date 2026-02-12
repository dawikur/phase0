// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Test;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

module Complication {

class SunMoon extends Text {
	hidden var moon_phase_ as Lang.Number = 0;

	function initialize() {
		Text.initialize(Complications.COMPLICATION_TYPE_SUNRISE);

		self.label_ = Lang.format("$1$     $2$", [
			Application.loadResource(Rez.Strings.LABEL_DAWN) as Lang.String,
			Application.loadResource(Rez.Strings.LABEL_DUSK) as Lang.String,
		]);

		self.value_bg_ = "00:00   00:00";

		self.justify_ = Graphics.TEXT_JUSTIFY_CENTER;
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.value_ = self.getValue_();
		self.moon_phase_ = self.getMoonPhase_(Time.now());

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
			pos_y += Render.labelHeight(_dc) + self.spacing_;
		}

		Render.icons(_dc, pos_x, pos_y, "" + (Font.ICON_MOON0 + self.moon_phase_), "");
	}

	function getValue_() as Lang.String {
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
		var sunset_info = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);

		return Lang.format("$1$:$2$   $3$:$4$", [
			sunrise_info.hour.format("%02d"),
			sunrise_info.min.format("%02d"),
			sunset_info.hour.format("%02d"),
			sunset_info.min.format("%02d"),
		]);
	}

	function getMoonPhase_(_moment as Time.Moment) as Lang.Number {
		var LUNAR_CYCLE_DAYS = 29.530588853;
		var SECONDS_PER_DAY = 86400;
		var NEW_MOON_REF = 947182440; // Jan 6, 2000 18:14 UTC

		var seconds_since = _moment.value() - NEW_MOON_REF;
		var days_since = seconds_since.toFloat() / SECONDS_PER_DAY;

		// Continuous phase in range [0, 1)
		var phase = days_since / LUNAR_CYCLE_DAYS;
		phase -= Math.floor(phase);

		// Center each phase in its bucket
		var phaseIndex = Math.floor((phase * 8) + 0.5).toNumber();

		// Wrap just in case
		if (phaseIndex == 8) {
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
			Time.Gregorian.moment({
				:year  => 2026,
				:month => 2,
				:day   => 17,
				:hour  => 13,
				:min   => 1,
				:sec   => 0
			}),
		];
		var new_moons_size = new_moons.size();

		var moon_phases = [
			/* day    phase */
			/*   0 */ 0, 0,
			/*   2 */ 1, 1, 1, 1,
			/*   6 */ 2, 2, 2, 9,
			/*  10 */ 3, 3, 3,
			/*  13 */ 4, 4, 4, 4,
			/*  17 */ 5, 5, 5, 9,
			/*  21 */ 6, 6, 6, 9,
			/*  25 */ 7, 7, 7,
			/*  28 */ 0, 0,
			/*  30 */ 0, 9,
			/*  32 */ 1, 1,
		];
		var moon_phases_size = moon_phases.size();

		var sun_moon = new SunMoon();

		for (var i = 0; i < new_moons_size; ++i) {
			var new_moon = new_moons[i];

			for (var day = 0; day < moon_phases_size; ++day) {
				var moon_phase = moon_phases[day];

				if (moon_phase == 9) {
					continue;
				}

				_logger.debug(Lang.format(
					"[$1$] Day: $2$, Moon phase $3$", [
						i,
						day,
						moon_phase,
					]
				));

				Test.assertEqual(
					sun_moon.getMoonPhase(new_moon.add(one_day.multiply(day))),
					moon_phase
				);
			}
		}

		return true;
	}
}

} // module Complication
