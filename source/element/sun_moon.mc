// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

module Element {

class SunMoon {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	hidden var spacing_ as Lang.Number = Render.SPACING;

	hidden var header_ as Lang.String = "Dawn     Dusk";

	hidden var dawn_dusk_ as Lang.String = "";
	hidden var moon_phase_ as Lang.Float = 0.0;

	function initialize() {
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

		// TODO: dim previous event
		// TODO: handle 12/24h times
		if (self.dawn_dusk_.length() == 0) {
			var text = "00:00   00:00";
			Render.textSmallColor(_dc, pos_x, pos_y, text, Graphics.TEXT_JUSTIFY_CENTER, Render.COLOR_BG);
		} else {
			Render.textSmall(_dc, pos_x, pos_y, self.dawn_dusk_, Graphics.TEXT_JUSTIFY_CENTER);
		}

		// ---- moon ----

		pos_y = self.pos_y;
		pos_y += (Render.labelHeight(_dc) + self.spacing_ + Render.textSmallHeight(_dc)) / 2;

		var moon_phase = Math.round(self.moon_phase_ * 8).toNumber();
		Render.icons(_dc, pos_x, pos_y, "" + (Font.ICON_MOON0 + moon_phase), "");
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var now = Time.now();

		self.refreshDawnDusk(now);
		self.refreshMoonPhase(now);

		if (self.dawn_dusk_.length() != 0) {
			Cache.setValue("dawn_dusk", self.dawn_dusk_);
		} else {
			var data = Cache.getValue("dawn_dusk", 86400); // 24 hours
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

		self.dawn_dusk_ = Lang.format("$1$:$2$   $3$:$4$", [
			sunrise_info.hour.format("%02d"),
			sunrise_info.min.format("%02d"),
			sunset_info.hour.format("%02d"),
			sunset_info.min.format("%02d"),
		]);
	}

	function refreshMoonPhase(_now as Time.Moment) as Void {
		var LUNAR_CYCLE_DAYS = 29.530588853;
		var SECONDS_PER_DAY = 86400;
		var NEW_MOON_REF = 947182440; // Jan 6, 2000 18:14 UTC

		var now = _now.value();
		var seconds_since = now - NEW_MOON_REF;
		var days_since = seconds_since.toFloat() / SECONDS_PER_DAY;

		var phase_days = days_since - Math.floor(days_since / LUNAR_CYCLE_DAYS) * LUNAR_CYCLE_DAYS;
		if (phase_days < 0) {
			phase_days += LUNAR_CYCLE_DAYS;
		}

		phase_days = Math.round(phase_days) as Lang.Float;

		self.moon_phase_ = phase_days / LUNAR_CYCLE_DAYS;
	}
}

} // module Element
