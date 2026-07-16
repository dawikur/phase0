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
		static const CACHE_TTL_HOURS = 48;
		static const CACHE_KEY_SUNRISE = "dawn_dusk_sunrise";
		static const CACHE_KEY_SUNSET = "dawn_dusk_sunset";
		static const EVENT_DISPLAY_OFFSET_SECONDS = 5 * 60;

		static const VALUE_BOTH = 0;
		static const VALUE_DAWN = 1;
		static const VALUE_DUSK = 2;

		static const MODE_SUN = 1 << 1;
		static const MODE_MOON = 1 << 2;
		static const MODE_AND = 1 << 3;
		static const MODE_OR = 1 << 4;

		hidden var moon_phase_ as Lang.Number = 0;

		hidden var dawn_ as Lang.String = "";
		hidden var dusk_ as Lang.String = "";
		hidden var sunrise_seconds_ as Lang.Number? = null;
		hidden var sunset_seconds_ as Lang.Number? = null;
		hidden var value_mode_ as Lang.Number = VALUE_BOTH;
		hidden var sunrise_before_sunset_ as Lang.Boolean = true;
		hidden var content_width_ as Lang.Number = 0;
		hidden var content_height_ as Lang.Number = 0;
		hidden var icon_width_ as Lang.Number = 0;
		hidden var dawn_dusk_width_ as Lang.Number = 0;
		hidden var has_icon_ as Lang.Boolean = false;

		hidden var show_label_ as Lang.Boolean = true;

		hidden var dawn_label_ as Lang.String;
		hidden var dusk_label_ as Lang.String;
		hidden var mode_ as Lang.Number;
		hidden var on_top_ as Lang.Boolean;

		var properties as Properties.Widget;

		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean,
			_mode as Lang.Number
		) {
			Base.initialize(
				Toybox has :Complications
					? Complications.COMPLICATION_TYPE_SUNRISE
					: null
			);

			self.properties = _properties;

			self.mode_ = _mode;
			self.on_top_ = _on_top;
			self.has_icon_ = (self.mode_ & (MODE_MOON | MODE_SUN)) != 0;

			self.dawn_label_ = Resources.get(Rez.Strings.LABEL_DAWN);
			self.dusk_label_ = Resources.get(Rez.Strings.LABEL_DUSK);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.dawn_ = "";
			self.dusk_ = "";
			self.sunrise_seconds_ = null;
			self.sunset_seconds_ = null;
			self.sunrise_before_sunset_ = true;

			var now = Time.now();
			self.moon_phase_ = SunMoon.MoonPhase(now);

			var sunrise = null;
			var sunset = null;
			var weather = Weather.getCurrentConditions();
			var location =
				weather != null ? weather.observationLocationPosition : null;

			if (location != null) {
				var sunrise_moment = Weather.getSunrise(location, now);
				var sunset_moment = Weather.getSunset(location, now);

				if (sunrise_moment != null and sunset_moment != null) {
					sunrise = self.daySeconds_(sunrise_moment as Time.Moment);
					sunset = self.daySeconds_(sunset_moment as Time.Moment);
					self.saveSunTimes_(
						sunrise as Lang.Number,
						sunset as Lang.Number
					);
				}
			}

			if (sunrise == null or sunset == null) {
				sunrise = self.loadSunTime_(SunMoon.CACHE_KEY_SUNRISE);
				sunset = self.loadSunTime_(SunMoon.CACHE_KEY_SUNSET);
			}

			if (sunrise != null and sunset != null) {
				self.applySunTimes_(
					sunrise as Lang.Number,
					sunset as Lang.Number
				);
			}
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(_dc, _size_x, _size_y);

			self.dawn_dusk_width_ = Render.TextWidth(
				_dc,
				"00:00",
				Render.SIZE_SMALL
			);

			if (self.has_icon_) {
				self.icon_width_ = Render.IconsWidth(_dc, Fonts.ICON_MOON_00);
			} else {
				self.icon_width_ = Render.SPACING;
			}

			self.updateValueMode_();

			self.show_label_ =
				Render.LabelHeight(_dc) +
					Render.SPACING +
					Render.TextHeight(_dc, Render.SIZE_SMALL) <=
				self.size_y;
			self.updateContentHeight_(_dc);
		}

		function render(_dc as Graphics.Dc) as Void {
			self.updateValueMode_();
			self.updateContentHeight_(_dc);

			var pos_x = self.centerX();
			var pos_y = self.pos_y;

			if (self.show_label_ and self.on_top_) {
				self.renderLabel_(_dc, pos_x, pos_y);
				pos_y += Render.LabelHeight(_dc) + Render.SPACING;
			}

			self.renderValue_(_dc, pos_x, pos_y);
			pos_y += Render.TextHeight(_dc, Render.SIZE_SMALL);

			if (self.show_label_ and !self.on_top_) {
				self.renderLabel_(_dc, pos_x, pos_y);
				pos_y += Render.LabelHeight(_dc) + Render.SPACING;
			}
		}

		hidden function layoutWidth_(_mode as Lang.Number) as Lang.Number {
			if (_mode == VALUE_DAWN || _mode == VALUE_DUSK) {
				return self.icon_width_ + self.dawn_dusk_width_;
			}
			return 2 * self.dawn_dusk_width_ + self.icon_width_;
		}

		hidden function updateValueMode_() as Void {
			self.value_mode_ = VALUE_BOTH;
			if (
				(self.mode_ & MODE_OR) != 0 and
				self.size_x < self.layoutWidth_(VALUE_BOTH)
			) {
				self.value_mode_ = self.currentValueMode_();
			}

			self.content_width_ = self.layoutWidth_(self.value_mode_);
		}

		hidden function updateContentHeight_(_dc as Graphics.Dc) as Void {
			self.content_height_ = Render.TextHeight(_dc, Render.SIZE_SMALL);
			if (self.show_label_) {
				self.content_height_ +=
					Render.LabelHeight(_dc) + Render.SPACING;
			}
		}

		hidden function applySunTimes_(
			_sunrise_seconds as Lang.Number,
			_sunset_seconds as Lang.Number
		) as Void {
			self.sunrise_seconds_ = _sunrise_seconds;
			self.sunset_seconds_ = _sunset_seconds;
			self.dawn_ = self.formatTime_(_sunrise_seconds);
			self.dusk_ = self.formatTime_(_sunset_seconds);
			self.sunrise_before_sunset_ = _sunrise_seconds <= _sunset_seconds;
		}

		hidden function currentValueMode_() as Lang.Number {
			if (self.sunrise_seconds_ == null or self.sunset_seconds_ == null) {
				return VALUE_DAWN;
			}

			var now_seconds = self.daySeconds_(Time.now());
			var sunrise_seconds = self.sunrise_seconds_ as Lang.Number;
			var sunset_seconds = self.sunset_seconds_ as Lang.Number;
			var dawn_end = self.dayWrap_(
				sunrise_seconds + SunMoon.EVENT_DISPLAY_OFFSET_SECONDS
			);
			var dusk_end = self.dayWrap_(
				sunset_seconds + SunMoon.EVENT_DISPLAY_OFFSET_SECONDS
			);

			return self.isWithinDayRange_(now_seconds, dusk_end, dawn_end)
				? VALUE_DAWN
				: VALUE_DUSK;
		}

		hidden function dayWrap_(_seconds as Lang.Number) as Lang.Number {
			return _seconds % (24 * 60 * 60);
		}

		hidden function isWithinDayRange_(
			_value as Lang.Number,
			_start as Lang.Number,
			_end as Lang.Number
		) as Lang.Boolean {
			if (_start <= _end) {
				return _start <= _value and _value < _end;
			}

			return _start <= _value or _value < _end;
		}

		hidden function formatTime_(_seconds as Lang.Number) as Lang.String {
			var hour = _seconds / 3600;
			var min = (_seconds % 3600) / 60;
			return Lang.format("$1$:$2$", [
				Data.Units.convertHour(hour).format("%02d"),
				min.format("%02d"),
			]);
		}

		hidden function daySeconds_(_moment as Time.Moment) as Lang.Number {
			var info = Time.Gregorian.info(_moment, Time.FORMAT_SHORT);
			return info.hour * 3600 + info.min * 60 + info.sec;
		}

		hidden function saveSunTimes_(
			_sunrise as Lang.Number,
			_sunset as Lang.Number
		) as Void {
			Cache.setValue(SunMoon.CACHE_KEY_SUNRISE, _sunrise);
			Cache.setValue(SunMoon.CACHE_KEY_SUNSET, _sunset);
		}

		hidden function loadSunTime_(
			_cache_key as Lang.String
		) as Lang.Number? {
			var value = Cache.getValue(_cache_key, SunMoon.CACHE_TTL_HOURS);
			return value != null ? value as Lang.Number : null;
		}

		hidden function renderLabel_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_pos_y as Lang.Number
		) as Void {
			if (self.value_mode_ != VALUE_BOTH) {
				var label = self.labelForValueMode_(self.value_mode_);
				var content_width = self.dawn_dusk_width_;
				if (self.has_icon_) {
					content_width += self.icon_width_;
				}
				Render.Label(
					_dc,
					Properties.general.accent,
					CenterStart(_pos_x, content_width) + content_width / 2,
					_pos_y,
					label,
					Graphics.TEXT_JUSTIFY_CENTER
				);
				return;
			}

			var pos_x = CenterStart(_pos_x, self.content_width_);
			var left_value_mode = self.leftValueMode_();
			var right_value_mode = self.rightValueMode_();

			if (self.value_mode_ != right_value_mode) {
				pos_x += self.dawn_dusk_width_;
				Render.Label(
					_dc,
					Properties.general.accent,
					pos_x + (self.has_icon_ ? Render.SPACING : 0),
					_pos_y,
					self.labelForValueMode_(left_value_mode),
					Graphics.TEXT_JUSTIFY_RIGHT
				);
			}

			pos_x += self.icon_width_;

			if (self.value_mode_ != left_value_mode) {
				Render.Label(
					_dc,
					Properties.general.accent,
					pos_x - (self.has_icon_ ? Render.SPACING : 0),
					_pos_y,
					self.labelForValueMode_(right_value_mode),
					Graphics.TEXT_JUSTIFY_LEFT
				);
			}
		}

		hidden function renderValue_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_pos_y as Lang.Number
		) as Void {
			var color =
				self.dawn_.length() != 0 and self.dusk_.length() != 0
					? Properties.general.foreground
					: Properties.general.shade;
			var pos_x = CenterStart(_pos_x, self.content_width_);
			var left_value_mode = self.leftValueMode_();
			var right_value_mode = self.rightValueMode_();

			if (self.value_mode_ == VALUE_BOTH || self.isLeftValueMode_()) {
				pos_x += self.dawn_dusk_width_;
				Render.Text(
					_dc,
					color,
					pos_x,
					_pos_y,
					Render.SIZE_SMALL,
					self.textForValueMode_(
						self.value_mode_ == VALUE_BOTH
							? left_value_mode
							: self.value_mode_
					),
					Graphics.TEXT_JUSTIFY_RIGHT
				);
			}

			pos_x += self.icon_width_ / 2;
			if (self.mode_ & MODE_MOON) {
				self.renderMoon_(_dc, pos_x, _pos_y);
			} else if (self.mode_ & MODE_SUN) {
				self.renderSun_(_dc, pos_x, _pos_y);
			}
			pos_x += self.icon_width_ / 2;

			if (self.value_mode_ == VALUE_BOTH || !self.isLeftValueMode_()) {
				Render.Text(
					_dc,
					color,
					pos_x,
					_pos_y,
					Render.SIZE_SMALL,
					self.textForValueMode_(
						self.value_mode_ == VALUE_BOTH
							? right_value_mode
							: self.value_mode_
					),
					Graphics.TEXT_JUSTIFY_LEFT
				);
			}
		}

		hidden function leftValueMode_() as Lang.Number {
			return self.sunrise_before_sunset_ ? VALUE_DAWN : VALUE_DUSK;
		}

		hidden function rightValueMode_() as Lang.Number {
			return self.sunrise_before_sunset_ ? VALUE_DUSK : VALUE_DAWN;
		}

		hidden function isLeftValueMode_() as Lang.Boolean {
			return self.value_mode_ == self.leftValueMode_();
		}

		hidden function labelForValueMode_(
			_value_mode as Lang.Number
		) as Lang.String {
			return _value_mode == VALUE_DAWN
				? self.dawn_label_
				: self.dusk_label_;
		}

		hidden function textForValueMode_(
			_value_mode as Lang.Number
		) as Lang.String {
			if (_value_mode == VALUE_DAWN) {
				return self.dawn_.length() != 0 ? self.dawn_ : "00:00";
			}
			return self.dusk_.length() != 0 ? self.dusk_ : "00:00";
		}

		hidden function renderMoon_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_pos_y as Lang.Number
		) as Void {
			var is_new_moon = self.moon_phase_ == 0;
			var is_full_moon = self.moon_phase_ == SunMoon.MOON_PHASES / 2;
			var moon_icon = (
				Fonts.ICON_MOON_00.toCharArray()[0] + self.moon_phase_
			).toString();
			var pos_y = self.iconPosY_(_dc, _pos_y);

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

		hidden function renderSun_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_pos_y as Lang.Number
		) as Void {
			var pos_y = self.iconPosY_(_dc, _pos_y);
			var value_mode =
				self.value_mode_ == VALUE_BOTH
					? self.currentValueMode_()
					: self.value_mode_;

			if (value_mode == VALUE_DAWN) {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					_pos_x,
					pos_y,
					Fonts.ICON_DAWN,
					"",
					Graphics.TEXT_JUSTIFY_CENTER
				);
			} else {
				Render.Icons(
					_dc,
					Properties.general.foreground,
					_pos_x,
					pos_y,
					Fonts.ICON_DUSK,
					"",
					Graphics.TEXT_JUSTIFY_CENTER
				);
			}
		}

		hidden function iconPosY_(
			_dc as Graphics.Dc,
			_value_pos_y as Lang.Number
		) as Lang.Number {
			if (self.value_mode_ != VALUE_BOTH) {
				return AlignCenter(
					_value_pos_y - Render.SPACING,
					Render.TextHeight(_dc, Render.SIZE_SMALL),
					Render.IconsHeight(_dc)
				);
			}

			var content_pos_y =
				self.show_label_ and self.on_top_
					? _value_pos_y -
						(self.content_height_ -
							Render.TextHeight(_dc, Render.SIZE_SMALL))
					: _value_pos_y;

			return AlignCenter(
				content_pos_y,
				self.content_height_,
				Render.IconsHeight(_dc)
			);
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

	class DawnAndDusk extends SunMoon {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			SunMoon.initialize(_properties, _on_top, SunMoon.MODE_AND);
		}
	}

	class DawnOrDusk extends SunMoon {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			SunMoon.initialize(_properties, _on_top, SunMoon.MODE_OR);
		}
	}

	class DawnAndDuskMoon extends SunMoon {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			SunMoon.initialize(
				_properties,
				_on_top,
				SunMoon.MODE_AND | SunMoon.MODE_MOON
			);
		}
	}

	class DawnOrDuskMoon extends SunMoon {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			SunMoon.initialize(
				_properties,
				_on_top,
				SunMoon.MODE_OR | SunMoon.MODE_MOON
			);
		}
	}

	class DawnAndDuskSun extends SunMoon {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			SunMoon.initialize(
				_properties,
				_on_top,
				SunMoon.MODE_AND | SunMoon.MODE_SUN
			);
		}
	}

	class DawnOrDuskSun extends SunMoon {
		function initialize(
			_properties as Properties.Widget,
			_on_top as Lang.Boolean
		) {
			SunMoon.initialize(
				_properties,
				_on_top,
				SunMoon.MODE_OR | SunMoon.MODE_SUN
			);
		}
	}
} // module Widgets
