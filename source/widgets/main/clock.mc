// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {
	class Clock extends Main {
		hidden var time_ as Lang.String = "";

		var properties as Properties.Clock;

		function initialize(_properties as Properties.Clock) {
			Main.initialize(null);

			self.properties = _properties;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var clock = System.getClockTime();

			var hour = Data.Units.convertHour(clock.hour);
			self.time_ = Lang.format("$1$:$2$", [
				hour.format("%02d"),
				clock.min.format("%02d"),
			]);
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number,
			_is_small as Lang.Boolean
		) as Void {
			Base.resize(_dc, _size_x, _size_y, _is_small);

			self.is_small =
				self.properties.height == Properties.SMALL or
				(self.properties.height == Properties.AUTO and _is_small);

			if (
				Base.Fits(
					Render.ClockWidth(_dc, "00:00", self.is_small),
					Render.ClockHeight(_dc, self.is_small),
					_size_x,
					_size_y
				)
			) {
				return;
			}

			self.is_small = Render.SIZE_SMALL;
		}

		function render(_dc as Graphics.Dc) as Void {
			var center_x = self.centerX();
			var center_y = self.centerY();

			Render.Clock(
				_dc,
				self.properties.foreground,
				self.properties.background,
				center_x,
				center_y,
				self.is_small,
				self.time_,
				"88:88"
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			var center_x = self.centerX();
			var center_y = self.centerY();

			Render.Clock(
				_dc,
				self.properties.foreground,
				self.properties.background,
				center_x,
				center_y,
				self.is_small,
				self.time_,
				""
			);
		}
	}
} // module Widgets
