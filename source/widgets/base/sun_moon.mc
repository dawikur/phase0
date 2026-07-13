// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;
import Toybox.Time;
import Toybox.Weather;

module Widgets {
	class SunMoon extends Base {
		static const MOON_PHASES = 16;
		static const VALUE_BOTH = 0;
		static const VALUE_DAWN = 1;
		static const VALUE_DUSK = 2;

		hidden var moon_phase_ as Lang.Number = 0;

		hidden var dawn_label_ as Lang.String = "";
		hidden var dusk_label_ as Lang.String = "";
		hidden var dawn_ as Lang.String = "";
		hidden var dusk_ as Lang.String = "";
		hidden var value_mode_ as Lang.Number = VALUE_BOTH;
		hidden var next_is_dawn_ as Lang.Boolean = true;
		hidden var group_width_ as Lang.Number = 0;
		hidden var dawn_width_ as Lang.Number = 0;
		hidden var dusk_width_ as Lang.Number = 0;
		hidden var icon_width_ as Lang.Number = 0;

		hidden var on_top_ as Lang.Boolean;
		hidden var show_label_ as Lang.Boolean = true;

		var properties as Properties.Widget;

		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			Base.initialize(Base.Complication(:sunrise));

			self.properties = _properties;

			self.on_top_ = _on_top;
			self.dawn_label_ = Resources.get(Rez.Strings.LABEL_DAWN);
			self.dusk_label_ = Resources.get(Rez.Strings.LABEL_DUSK);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.refreshValue_();
			self.moon_phase_ = SunMoon.MoonPhase(Time.now());

			var cache_key = Data.Units.is_24_hour
				? "dawn_dusk_24h"
				: "dawn_dusk_12h";
			var next_cache_key = cache_key + "_next";
			if (self.dawn_.length() != 0 and self.dusk_.length() != 0) {
				Cache.setValue(cache_key, self.value_());
				Cache.setValue(next_cache_key, self.next_is_dawn_ ? 1 : 0);
			} else {
				var data = Cache.getValue(cache_key, 24);
				if (data != null) {
					var value = data as Lang.String;
					if (10 <= value.length()) {
						self.dawn_ = value.substring(0, 5) as Lang.String;
						self.dusk_ =
							value.substring(value.length() - 5, null) as
							Lang.String;
					}
				}

				var next = Cache.getValue(next_cache_key, 24);
				if (next != null) {
					self.next_is_dawn_ = (next as Lang.Number) == 1;
				}
			}

			self.updateLayout_(_dc);
		}

		function value_() as Lang.String {
			return Lang.format("$1$   $2$", [self.dawn_, self.dusk_]);
		}

		function labelWidth_(
			_dc as Graphics.Dc,
			_mode as Lang.Number
		) as Lang.Number {
			if (_mode == VALUE_DAWN) {
				return Render.LabelWidth(_dc, self.dawn_label_);
			}
			if (_mode == VALUE_DUSK) {
				return Render.LabelWidth(_dc, self.dusk_label_);
			}
			return Render.LabelWidth(
				_dc,
				Lang.format("$1$   $2$", [self.dawn_label_, self.dusk_label_])
			);
		}

		function dawnWidth_(_dc as Graphics.Dc) as Lang.Number {
			return Render.TextWidth(
				_dc,
				self.dawnOrPlaceholder_(),
				Render.SIZE_SMALL
			);
		}

		function duskWidth_(_dc as Graphics.Dc) as Lang.Number {
			return Render.TextWidth(
				_dc,
				self.duskOrPlaceholder_(),
				Render.SIZE_SMALL
			);
		}

		function iconWidth_(_dc as Graphics.Dc) as Lang.Number {
			return Render.IconsWidth(_dc, Fonts.ICON_MOON_00);
		}

		function groupWidth_(
			_dc as Graphics.Dc,
			_mode as Lang.Number
		) as Lang.Number {
			var dawn_width = self.dawnWidth_(_dc);
			var dusk_width = self.duskWidth_(_dc);
			var icon_width = self.iconWidth_(_dc);

			if (_mode == VALUE_DAWN) {
				return dawn_width + Render.SPACING + icon_width;
			}
			if (_mode == VALUE_DUSK) {
				return icon_width + Render.SPACING + dusk_width;
			}
			return (
				dawn_width +
				Render.SPACING +
				icon_width +
				Render.SPACING +
				dusk_width
			);
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number,
			_is_small as Lang.Boolean
		) as Void {
			Base.resize(_dc, _size_x, _size_y, _is_small);
			self.updateLayout_(_dc);
		}

		function updateLayout_(_dc as Graphics.Dc) as Void {
			self.value_mode_ = VALUE_BOTH;

			if (self.groupWidth_(_dc, self.value_mode_) > self.size_x) {
				self.value_mode_ = self.next_is_dawn_ ? VALUE_DAWN : VALUE_DUSK;
			}

			self.show_label_ =
				!self.is_small and
				Render.LabelHeight(_dc) +
					Render.SPACING +
					Render.TextHeight(_dc, Render.SIZE_SMALL) <=
					self.size_y and
				self.labelWidth_(_dc, self.value_mode_) <= self.size_x;
		}

		function render(_dc as Graphics.Dc) as Void {
			// ---- header ----

			var pos_x = self.centerX();
			var pos_y = self.pos_y;

			// ---- label on top ----

			if (self.on_top_) {
				if (self.show_label_) {
					Render.Label(
						_dc,
						Properties.general.accent,
						pos_x,
						pos_y,
						self.label_(),
						Graphics.TEXT_JUSTIFY_CENTER
					);
					pos_y += Render.LabelHeight(_dc) + Render.SPACING;
				}
			}

			// ---- value ----

			self.renderValue_(_dc, pos_x, pos_y);
			pos_y += Render.TextHeight(_dc, Render.SIZE_SMALL);

			// ---- label on bottom ----

			if (!self.on_top_) {
				if (self.show_label_) {
					Render.Label(
						_dc,
						Properties.general.accent,
						pos_x,
						pos_y,
						self.label_(),
						Graphics.TEXT_JUSTIFY_CENTER
					);
					pos_y += Render.LabelHeight(_dc) + Render.SPACING;
				}
			}
		}

		function renderMoon_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_pos_y as Lang.Number
		) as Void {
			var is_new_moon = self.moon_phase_ == 0;
			var is_full_moon = self.moon_phase_ == SunMoon.MOON_PHASES / 2;
			var moon_icon = (
				Fonts.ICON_MOON_00.toCharArray()[0] + self.moon_phase_
			).toString();
			var pos_y = Base.AlignCenter(
				_pos_y,
				Render.TextHeight(_dc, Render.SIZE_SMALL),
				Render.IconsHeight(_dc)
			);

			if (is_new_moon) {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					_pos_x,
					pos_y,
					"",
					moon_icon,
					Graphics.TEXT_JUSTIFY_CENTER
				);
			} else if (is_full_moon) {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					_pos_x,
					pos_y,
					"",
					moon_icon,
					Graphics.TEXT_JUSTIFY_CENTER
				);
				Render.Icons(
					_dc,
					Properties.general.foreground,
					_pos_x + 1,
					pos_y + 1,
					moon_icon,
					"",
					Graphics.TEXT_JUSTIFY_CENTER
				);
			} else {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					_pos_x,
					pos_y,
					moon_icon,
					moon_icon,
					Graphics.TEXT_JUSTIFY_CENTER
				);
			}
		}

		function dawnOrPlaceholder_() as Lang.String {
			return self.dawn_.length() != 0 ? self.dawn_ : "00:00";
		}

		function duskOrPlaceholder_() as Lang.String {
			return self.dusk_.length() != 0 ? self.dusk_ : "00:00";
		}

		function label_() as Lang.String {
			if (self.value_mode_ == VALUE_DAWN) {
				return self.dawn_label_;
			}
			if (self.value_mode_ == VALUE_DUSK) {
				return self.dusk_label_;
			}
			return Lang.format("$1$   $2$", [
				self.dawn_label_,
				self.dusk_label_,
			]);
		}

		function renderValue_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_pos_y as Lang.Number
		) as Void {
			var color =
				self.dawn_.length() != 0 and self.dusk_.length() != 0
					? Properties.general.foreground
					: Properties.general.shade;
			var dawn = self.dawnOrPlaceholder_();
			var dusk = self.duskOrPlaceholder_();
			self.dawn_width_ = self.dawnWidth_(_dc);
			self.dusk_width_ = self.duskWidth_(_dc);
			self.icon_width_ = self.iconWidth_(_dc);
			self.group_width_ = self.groupWidth_(_dc, self.value_mode_);

			if (self.value_mode_ == VALUE_DAWN) {
				var group_start = Base.CenterStart(_pos_x, self.group_width_);
				var moon_x =
					group_start +
					self.dawn_width_ +
					Render.SPACING +
					self.icon_width_ / 2;

				Render.Text(
					_dc,
					color,
					group_start + self.dawn_width_,
					_pos_y,
					Render.SIZE_SMALL,
					dawn,
					Graphics.TEXT_JUSTIFY_RIGHT
				);
				self.renderMoon_(_dc, moon_x, _pos_y);
				return;
			}

			if (self.value_mode_ == VALUE_DUSK) {
				var group_start = Base.CenterStart(_pos_x, self.group_width_);
				var moon_x = group_start + self.icon_width_ / 2;

				self.renderMoon_(_dc, moon_x, _pos_y);
				Render.Text(
					_dc,
					color,
					group_start + self.icon_width_ + Render.SPACING,
					_pos_y,
					Render.SIZE_SMALL,
					dusk,
					Graphics.TEXT_JUSTIFY_LEFT
				);
				return;
			}

			var group_start = Base.CenterStart(_pos_x, self.group_width_);
			var moon_x =
				group_start +
				self.dawn_width_ +
				Render.SPACING +
				self.icon_width_ / 2;

			Render.Text(
				_dc,
				color,
				group_start + self.dawn_width_,
				_pos_y,
				Render.SIZE_SMALL,
				dawn,
				Graphics.TEXT_JUSTIFY_RIGHT
			);
			self.renderMoon_(_dc, moon_x, _pos_y);
			Render.Text(
				_dc,
				color,
				group_start +
					self.dawn_width_ +
					Render.SPACING +
					self.icon_width_ +
					Render.SPACING,
				_pos_y,
				Render.SIZE_SMALL,
				dusk,
				Graphics.TEXT_JUSTIFY_LEFT
			);
		}

		function refreshValue_() as Void {
			self.dawn_ = "";
			self.dusk_ = "";

			if (!(Toybox has :Complications)) {
				return;
			}

			var weather = Weather.getCurrentConditions();
			if (weather == null) {
				return;
			}

			var location = weather.observationLocationPosition;
			if (location == null) {
				return;
			}

			var now = Time.now();

			var sunrise = Weather.getSunrise(location, now);
			if (sunrise == null) {
				return;
			}

			var sunset = Weather.getSunset(location, now);
			if (sunset == null) {
				return;
			}

			self.next_is_dawn_ =
				now.compare(sunrise) < 0 or now.compare(sunset) >= 0;

			var sunrise_info = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
			var sunrise_hour = Data.Units.convertHour(sunrise_info.hour);
			var sunrise_min = sunrise_info.min;
			var sunset_info = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);
			var sunset_hour = Data.Units.convertHour(sunset_info.hour);
			var sunset_min = sunset_info.min;

			self.dawn_ = Lang.format("$1$:$2$", [
				sunrise_hour.format("%02d"),
				sunrise_min.format("%02d"),
			]);
			self.dusk_ = Lang.format("$1$:$2$", [
				sunset_hour.format("%02d"),
				sunset_min.format("%02d"),
			]);
		}

		static function MoonPhase(_moment as Time.Moment) as Lang.Number {
			var LUNAR_CYCLE_DAYS = 29.530588853;
			var SECONDS_PER_DAY = 86400;
			var NEW_MOON_REF = 947182440; // Jan 6, 2000 18:14 UTC

			var seconds_since = _moment.value() - NEW_MOON_REF;
			var days_since = seconds_since.toFloat() / SECONDS_PER_DAY;

			// Continuous phase in range [0, 1)
			var phase = days_since / LUNAR_CYCLE_DAYS;
			phase -= Math.floor(phase);

			// Center each phase in its bucket
			var phaseIndex = Math.floor(
				phase * SunMoon.MOON_PHASES + 0.5
			).toNumber();

			// Wrap just in case
			if (phaseIndex == SunMoon.MOON_PHASES) {
				phaseIndex = 0;
			}

			return phaseIndex;
		}

		(:test)
		static function MoonPhaseTest(_logger as Test.Logger) as Lang.Boolean {
			var one_day = new Time.Duration(24 * 60 * 60); // h * min * 60

			var new_moons = [
				Time.Gregorian.moment({
					:year => 2000,
					:month => 1,
					:day => 6,
					:hour => 18,
					:min => 14,
					:sec => 0,
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
				/*   0 */ 0, /*   1 */ 1, 1, /*   3 */ 2, 2, /*   5 */ 3, 3,
				/*   7 */ 4, 4, /*   9 */ 5, 5, /*  11 */ 6, 6, /*  13 */ 7,
				/*  14 */ 8, 8, /*  16 */ 9, 9, /*  17 */ 10, 10, /*  20 */ 11,
				11, /*  22 */ 12, 12, /*  24 */ 13, /*  25 */ 14, 14,
				/*  27 */ 15, 15, /*  29 */ 0, 0, /*   0 */ 1, 1, 2,
			];
			var moon_phases_size = moon_phases.size();

			for (var i = 0; i < new_moons_size; ++i) {
				var new_moon = new_moons[i];

				for (var day = 0; day < moon_phases_size; ++day) {
					var moon_phase = moon_phases[day];

					_logger.debug(
						Lang.format("[$1$] Day: $2$, Moon phase $3$", [
							i,
							day,
							moon_phase,
						])
					);

					Test.assertEqual(
						SunMoon.MoonPhase(new_moon.add(one_day.multiply(day))),
						moon_phase
					);
				}
			}

			return true;
		}
	}
} // module Widgets
