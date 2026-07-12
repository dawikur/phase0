// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Widgets {
	class Clock extends Main {
		hidden var time_ as Lang.String = "";

		var is_small as Lang.Boolean = false;

		var properties as Properties.Clock;

		function initialize(_properties as Properties.Clock) {
			Main.initialize(Complications.COMPLICATION_TYPE_INVALID);

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

		function render(_dc as Graphics.Dc) as Void {
			Render.Clock(
				_dc,
				self.properties.foreground,
				self.properties.background,
				self.pos_x + self.size_x / 2,
				self.pos_y + self.size_y / 2,
				self.properties.height == Properties.AUTO
					? self.is_small
					: self.properties.height == Properties.SMALL,
				self.time_,
				"88:88"
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			Render.Clock(
				_dc,
				self.properties.foreground,
				self.properties.background,
				self.pos_x + self.size_x / 2,
				self.pos_y + self.size_y / 2,
				self.properties.height == Properties.AUTO
					? self.is_small
					: self.properties.height == Properties.SMALL,
				self.time_,
				""
			);
		}
	}
} // module Widgets
