// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Widgets {
	class Clock extends Base {
		hidden var time_ as Lang.String = "";

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
			var hour = Data.Units.convertHour(Runtime.clock.hour);
			var min = Runtime.clock.min;
			self.time_ = Lang.format("$1$:$2$", [
				hour.format("%02d"),
				min.format("%02d"),
			]);
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(_dc, _size_x, _size_y);

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
					return;
				}
			}

			self.font_fg_ =
				Application.loadResource(Rez.Fonts.DIGITS_SMALL) as
				WatchUi.FontResource;
			self.font_bg_ =
				Application.loadResource(Rez.Fonts.DIGITS_SMALL_THIN) as
				WatchUi.FontResource;
		}

		function render(_dc as Graphics.Dc) as Void {
			var center_x = self.centerX();
			var center_y = self.centerY();

			Render.Clock(
				_dc,
				self.foreground_,
				self.background_,
				center_x,
				center_y,
				self.font_fg_,
				self.font_bg_,
				self.time_,
				"88:88"
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			var center_x = self.centerX();
			var center_y = self.centerY();

			Render.Clock(
				_dc,
				self.foreground_,
				self.background_,
				center_x,
				center_y,
				self.font_fg_,
				self.font_bg_,
				self.time_,
				""
			);
		}
	}
} // module Widgets
