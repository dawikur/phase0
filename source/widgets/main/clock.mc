// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Widgets {
	class Clock {
		hidden var time_ as Lang.String = "";
		hidden var small_ as Lang.Boolean;

		var pos_x as Lang.Number = 0;
		var pos_y as Lang.Number = 0;

		var size_x as Lang.Number = 0;
		var size_y as Lang.Number = 0;

		function initialize(_small as Lang.Boolean) {
			self.small_ = _small;
		}

		function contains(
			_x as Lang.Number,
			_y as Lang.Number
		) as Lang.Boolean {
			var pos_x = self.pos_x;
			var pos_y = self.pos_y;
			var end_x = pos_x + self.size_x;
			var end_y = pos_y + self.size_y;

			return pos_x <= _x and _x <= end_x and pos_y <= _y and _y <= end_y;
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var clock = System.getClockTime();

			var hour = Data.Units.convertHour(clock.hour);
			self.time_ = Lang.format("$1$:$2$", [
				hour.format("%02d"),
				clock.min.format("%02d"),
			]);
		}

		function render(
			_dc as Graphics.Dc,
			_is_night_mode as Lang.Boolean
		) as Void {
			if (self.time_.length() == 0) {
				self.refresh(_dc);
			}

			if (self.time_.length() == 0) {
				return;
			}

			Render.Clock(
				_dc,
				Properties.clock.color,
				Properties.clock.background,
				self.pos_x + self.size_x / 2,
				self.pos_y + self.size_y / 2,
				Properties.clock.height == Properties.AUTO
					? self.small_
					: Properties.clock.height == Properties.SMALL,
				self.time_,
				_is_night_mode ? "" : "88:88"
			);
		}
	}
} // module Widgets
