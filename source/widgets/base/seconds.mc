// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Widgets {
	class Seconds extends Base {
		hidden var value_ as Lang.String = "";

		hidden var is_small as Lang.Boolean = false;

		function initialize() {
			Base.initialize(null, RefreshRate.SEC);
		}

		function refresh(_dc as Graphics.Dc) as Void {
			self.value_ = Runtime.clock.sec.format("%02d");
		}

		function resize(
			_dc as Graphics.Dc,
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Void {
			Base.resize(_dc, _size_x, _size_y);
			self.is_small = Render.SIZE_REGULAR;
			if (
				!Fits(
					Render.TextWidth(_dc, "00", self.is_small),
					Render.TextHeight(_dc, self.is_small),
					_size_x,
					_size_y
				)
			) {
				self.is_small = Render.SIZE_SMALL;
			}
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
