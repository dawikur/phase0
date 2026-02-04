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
	hidden var header_style_ as Label.Style;

	hidden var fg_style_ as Label.Style;
	hidden var bg_style_ as Label.Style;

	hidden var moon_color_ as Lang.Number;
	hidden var moon_full_color_ as Lang.Number;

	hidden var dawn_dusk_ as Lang.String or Null;
	hidden var moon_phase_ as Lang.Float or Null;

	function initialize() {
		self.spacing_ = Font.SPACING_TINY;

		self.header_ = "Dawn Dusk";
		self.header_style_ = new Label.Style(Font.DOT_TINY, 0xFFAA00);

		self.fg_style_ = new Label.Style(Font.DOT_SMALL, 0xFFFFFF);
		self.bg_style_ = new Label.Style(Font.DOT_SMALL, 0x555555);

		self.moon_color_ = 0xAAAAAA;
		self.moon_full_color_ = 0xFFFFFF;

		self.dawn_dusk_ = null;
		self.moon_phase_ = null;
	}

	function render(_dc as Graphics.Dc) as Void {
		var pos_x = self.pos_x;
		var pos_y = self.pos_y;

		// ---- header ----

		self.header_style_.draw(_dc, pos_x, pos_y, self.header_, Graphics.TEXT_JUSTIFY_CENTER);
		pos_y += _dc.getFontHeight(self.header_style_.font) + self.spacing_;

		// ---- text ----

		if (self.dawn_dusk_ == null ) {
			var text = "00:00 00:00";
			self.bg_style_.draw(_dc, pos_x, pos_y, text, Graphics.TEXT_JUSTIFY_CENTER);
		} else {
			var text = self.dawn_dusk_ as Lang.String;
			self.fg_style_.draw(_dc, pos_x, pos_y, text, Graphics.TEXT_JUSTIFY_CENTER);
		}

		// ---- moon gauge ----

		pos_x -= self.spacing_;
		pos_y += self.spacing_;

		var gauge_max_height = _dc.getFontHeight(self.fg_style_.font);

		if (self.moon_phase_ != null) {
			var moon_phase = self.moon_phase_ as Lang.Float;

			if (moon_phase < 0.5) {
				var gauge_height = 2 * (moon_phase * gauge_max_height).toNumber();

				System.println("moon phase: " + moon_phase + ", gauge1: " + gauge_height);

				_dc.setColor(self.moon_color_, Graphics.COLOR_TRANSPARENT);
				_dc.fillRectangle(
					pos_x,
					pos_y + gauge_max_height - gauge_height,
					self.spacing_,
					gauge_height
				);
			} else if (0.5 < moon_phase) {
				var gauge_height = 2 * ((1.0 - moon_phase) * gauge_max_height).toNumber();

				System.println("moon phase: " + moon_phase + ", gauge2: " + gauge_height);

				_dc.setColor(self.moon_color_, Graphics.COLOR_TRANSPARENT);
				_dc.fillRectangle(
					pos_x,
					pos_y,
					self.spacing_,
					gauge_height
				);
			} else {
				System.println("moon phase: " + moon_phase + ", gauge: full");

				_dc.setColor(self.moon_full_color_, Graphics.COLOR_TRANSPARENT);
				_dc.fillRectangle(
					pos_x,
					pos_y,
					self.spacing_,
					gauge_max_height
				);
			}
		}

		_dc.setColor(self.bg_style_.color, Graphics.COLOR_TRANSPARENT);
		for (var i = 0; i < gauge_max_height; i += 2 * self.spacing_) {
			_dc.fillRectangle(
				pos_x,
				pos_y + i,
				1,
				1
			);
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {
		var now = Time.now();

		self.refreshDawnDusk(now);
		self.refreshMoonPhase(now);
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
