// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {
	class Seconds extends Main {
		hidden var value_ as Lang.String = "";

		var is_small as Lang.Boolean = false;

		function initialize() {
			Main.initialize(Complications.COMPLICATION_TYPE_INVALID);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			var clock = System.getClockTime();

			self.value_ = clock.sec.format("%02d");
		}

		function render(_dc as Graphics.Dc) as Void {
			Render.Text(
				_dc,
				Properties.general.foreground,
				self.pos_x,
				self.pos_y,
				self.is_small,
				self.value_,
				Render.JUSTIFY_LEFT
			);
		}

		function renderMinimal(_dc as Graphics.Dc) as Void {
			Render.Number(_dc, self.pos_x, self.pos_y, null, 2, self.is_small);
		}
	}
} // module Widgets
