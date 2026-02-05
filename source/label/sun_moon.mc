// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.Time;

module Label {

class SunMoon {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	hidden var spacing_ as Lang.Number = 0;

	hidden var header_ as Lang.String;

	hidden var dawn_dusk_ as Lang.String;
	hidden var moon_phase_ as Lang.Float;

	function initialize() {
		self.spacing_ = Font.SPACING_TINY;

		self.header_ = "Dawn Dusk";

		self.dawn_dusk_ = "";
		self.moon_phase_ = 0.0;
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.dawn_dusk_.length() == 0) {
			self.refresh(_dc);
		}

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		// ---- header ----

		Render.label(_dc, pos_x, pos_y, self.header_, Graphics.TEXT_JUSTIFY_CENTER);
		pos_y += Render.labelHeight(_dc) + self.spacing_;

		// ---- text ----

		if (self.dawn_dusk_.length() == 0) {
			var text = "00:00 00:00";
			Render.textSmall(_dc, pos_x, pos_y, text, Graphics.TEXT_JUSTIFY_CENTER);
		} else {
			var text = self.dawn_dusk_ as Lang.String;
			Render.textSmall(_dc, pos_x, pos_y, text, Graphics.TEXT_JUSTIFY_CENTER);
		}

		// ---- gauge ----

		pos_x -= self.spacing_;
		pos_y += self.spacing_;

		var value = 0;
		var from_bottom = Render.GAUGE_BOTTOM;

		var moon_phase = self.moon_phase_;
		if (moon_phase < 0.5) { // moon growing
			value = 2 * moon_phase;
		} else if (0.5 < moon_phase) { // moon shinking
			value = 2 * (1.0 - moon_phase);
			from_bottom = Render.GAUGE_TOP;
		} else { // full moon
			value = 1.0;
		}

		var gauge_max_height = Render.textSmallHeight(_dc);

		Render.gaugeSmall(_dc, pos_x, pos_y, value, gauge_max_height, from_bottom);
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var now = Time.now();

		self.refreshDawnDusk(now);
		self.refreshMoonPhase(now);

		if (self.dawn_dusk_.length() != 0) {
			Cache.setValue("dusk_dawn", self.dawn_dusk_);
		} else {
			var data = Cache.getValue("dusk_dawn", 86400); // 24 hours
			if (data != null) {
				self.dawn_dusk_ = data;
			}
		}
	}

	function refreshDawnDusk(_now as Time.Moment) as Void {
		var weather = Weather.getCurrentConditions();
		if (weather == null) {
			return;
		}

		var location = weather.observationLocationPosition;
		if (location == null) {
			return;
		}

		var sunrise = Weather.getSunrise(location, _now);
		if (sunrise == null) {
			return;
		}

		var sunset = Weather.getSunset(location, _now);
		if (sunset == null) {
			return;
		}

		var sunrise_info = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
		var sunset_info = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);

		self.dawn_dusk_ = Lang.format("$1$:$2$ $3$:$4$", [
			sunrise_info.hour.format("%02d"),
			sunrise_info.min.format("%02d"),
			sunset_info.hour.format("%02d"),
			sunset_info.min.format("%02d"),
		]);
	}

	function refreshMoonPhase(_now as Time.Moment) as Void {
		var LUNAR_CYCLE_SECONDS = 2551442; // 29.530588853 days * 86400 seconds
		var NEW_MOON_REF = 947182440; // Jan 6, 2000 18:14 UTC

		var now = _now.value();
		var seconds_since = now - NEW_MOON_REF;

		var phase_seconds = seconds_since % LUNAR_CYCLE_SECONDS;

		if (phase_seconds < 0) {
			phase_seconds += LUNAR_CYCLE_SECONDS;
		}

		self.moon_phase_ = phase_seconds.toFloat() / LUNAR_CYCLE_SECONDS;
	}
}

} // module Label
