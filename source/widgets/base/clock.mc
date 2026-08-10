// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Widgets {
	class Clock extends Base {
		hidden var hour_ as Lang.Number = -1;
		hidden var min_ as Lang.Number = -1;
		hidden var time_ as Lang.String = "";
		hidden var shade_ as Lang.String = "88:88";

		hidden var digit_width_ as Lang.Number = -1;
		hidden var colon_width_ as Lang.Number = -1;

		hidden var font_fg_ as WatchUi.FontResource;
		hidden var font_bg_ as WatchUi.FontResource;

		hidden var foreground_ as Lang.Number;
		hidden var background_ as Lang.Number;
		hidden var height_ as Lang.Number;

		function initialize(_properties as Properties.Clock) {
			Base.initialize(null, RefreshRate.MIN);

			self.font_fg_ =
				Application.loadResource(Rez.Fonts.DIGITS_REGULAR) as
				WatchUi.FontResource;
			self.font_bg_ =
				Application.loadResource(Rez.Fonts.DIGITS_REGULAR_THIN) as
				WatchUi.FontResource;

			self.foreground_ = _properties.foreground;
			self.background_ = _properties.background;
			self.height_ = _properties.height;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.hour_ = Data.Units.convertHour(Runtime.clock.hour);
			self.min_ = Runtime.clock.min;
			self.time_ = Lang.format("$1$:$2$", [
				self.hour_.format("%02d"),
				self.min_.format("%02d"),
			]);
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(_dc, _size_x, _size_y);
			self.hour_ = -1;
			self.min_ = -1;
			self.is_dirty_ = true;
			if (self.height_ != Properties.SMALL) {
				self.font_fg_ =
					Application.loadResource(Rez.Fonts.DIGITS_REGULAR) as
					WatchUi.FontResource;
				self.font_bg_ =
					Application.loadResource(Rez.Fonts.DIGITS_REGULAR_THIN) as
					WatchUi.FontResource;

				if (
					Fits(
						Render.ClockWidth(_dc, "00:00", self.font_fg_),
						Render.ClockHeight(_dc, self.font_fg_),
						_size_x,
						_size_y
					)
				) {
					self.digit_width_ =
						Render.ClockWidth(_dc, "0", self.font_fg_) -
						Render.SHADOW_OFFSET;
					self.colon_width_ =
						Render.ClockWidth(_dc, ":", self.font_fg_) -
						Render.SHADOW_OFFSET;

					return;
				}
			}

			self.font_fg_ =
				Application.loadResource(Rez.Fonts.DIGITS_SMALL) as
				WatchUi.FontResource;
			self.font_bg_ =
				Application.loadResource(Rez.Fonts.DIGITS_SMALL_THIN) as
				WatchUi.FontResource;

			self.digit_width_ =
				Render.ClockWidth(_dc, "0", self.font_fg_) -
				Render.SHADOW_OFFSET;
			self.colon_width_ =
				Render.ClockWidth(_dc, ":", self.font_fg_) -
				Render.SHADOW_OFFSET;
		}

		function render(_dc as Graphics.Dc) as Void {
			self.render_(_dc, self.pos_x, self.time_, self.shade_);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			self.render_(_dc, self.pos_x, self.time_, "");
		}

		function update(_dc as Graphics.Dc) as Void {
			self.update_(_dc, self.shade_);
		}

		function updateMinimal(_dc as Graphics.Dc) as Void {
			self.update_(_dc, "");
		}

		function invalidate() as Void {
			self.hour_ = -1;
			self.min_ = -1;
			self.is_dirty_ = true;
		}

		hidden function update_(
			_dc as Graphics.Dc,
			_shade as Lang.String
		) as Void {
			var previous_hour = self.hour_;
			var previous_min = self.min_;

			self.refresh(_dc);

			if (previous_hour < 0 or previous_min < 0) {
				self.updateRange_(_dc, 0, _shade);
			} else if (previous_hour != self.hour_) {
				var start = previous_hour / 10 == self.hour_ / 10 ? 1 : 0;
				self.updateRange_(_dc, start, _shade);
			} else if (previous_min != self.min_) {
				var start = previous_min / 10 == self.min_ / 10 ? 4 : 3;
				self.updateRange_(_dc, start, _shade);
			}
		}

		hidden function updateRange_(
			_dc as Graphics.Dc,
			_start as Lang.Number,
			_shade as Lang.String
		) as Void {
			var offset_x = _start * self.digit_width_;
			if (2 < _start) {
				offset_x += self.colon_width_ - self.digit_width_;
			}
			var pos_x = self.pos_x + offset_x;
			var width =
				4 * self.digit_width_ +
				self.colon_width_ +
				Render.SHADOW_OFFSET -
				offset_x;

			_dc.setClip(pos_x, self.pos_y, width, self.size_y);
			_dc.setColor(Render.background, Render.background);
			_dc.clear();

			var time = self.time_.substring(_start, null) as Lang.String;
			var shade = "";
			if (_shade.length() != 0) {
				shade = _shade.substring(_start, null) as Lang.String;
			}

			self.render_(_dc, pos_x, time, shade);
		}

		hidden function render_(
			_dc as Graphics.Dc,
			_pos_x as Lang.Number,
			_time as Lang.String,
			_shade as Lang.String
		) as Void {
			Render.Clock(
				_dc,
				self.foreground_,
				self.background_,
				_pos_x,
				self.centerY(),
				self.font_fg_,
				self.font_bg_,
				_time,
				_shade
			);
		}
	}
} // module Widgets
